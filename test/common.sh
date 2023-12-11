echo "getpid: $$" >&2

# Duplicated from src/share/poudriere/util.sh because it is too early to
# include that file.
write_atomic_cmp() {
	local dest="$1"
	local tmp ret

	ret=0
	tmp="$(TMPDIR="${dest%/*}" mktemp -t ${dest##*/})" ||
		err $? "write_atomic_cmp unable to create tmpfile in ${dest%/*}"
	cat > "${tmp}" || ret=$?
	if [ "${ret}" -ne 0 ]; then
		rm -f "${tmp}"
		return "${ret}"
	fi

	if ! cmp -s "${dest}" "${tmp}"; then
		rename "${tmp}" "${dest}"
	else
		unlink "${tmp}"
	fi
}

CMD="${0##*/}"
IN_TEST=1
SCRIPTPATH="${SCRIPTPREFIX}/${CMD}"
: ${BASEFS:=/var/tmp/poudriere/test}
POUDRIERE_ETC="${BASEFS}/etc"

: ${DISTFILES_CACHE:=$(mktemp -dt distfiles)}

mkdir -p ${POUDRIERE_ETC}/poudriere.d ${POUDRIERE_ETC}/run
rm -f "${POUDRIERE_ETC}/poudriere.conf"
write_atomic_cmp "${POUDRIERE_ETC}/poudriere.d/poudriere.conf" << EOF
NO_ZFS=yes
BASEFS=${BASEFS}
DISTFILES_CACHE=${DISTFILES_CACHE}
USE_TMPFS=all
USE_PROCFS=no
USE_FDESCFS=no
NOLINUX=yes
# jail -c options
NO_LIB32=yes
NO_SRC=yes
SHARED_LOCK_DIR="${POUDRIERE_ETC}/run"
IMMUTABLE_BASE=nullfs
$(env | grep -q 'CCACHE_STATIC_PREFIX' && { env | awk '/^CCACHE/ {print "export " $0}'; } || :)
EOF
write_atomic_cmp "${POUDRIERE_ETC}/poudriere.d/make.conf" << EOF
DEFAULT_VERSIONS+=	ssl=base
PKG_NOCOMPRESS=		t
PKG_COMPRESSION_FORMAT=	tar
EOF

: ${VERBOSE:=1}
: ${PARALLEL_JOBS:=2}

msg() {
	echo "$@"
}
msg_debug() {
	if [ ${VERBOSE} -le 1 ]; then
		msg_debug() { }
		return 0
	fi
	msg "[DEBUG] $@" >&2
}

msg_warn() {
	msg "[WARN] $@" >&2
}

msg_dev() {
	if [ ${VERBOSE} -le 2 ]; then
		msg_dev() { }
		return 0
	fi
	msg "[DEV] $@" >&2
}

_assert() {
	local -; set +x
	[ $# -ge 3 ] || eargs assert lineinfo expected actual msg
	local lineinfo="$1"
	local expected="$2"
	local actual="$3"
	shift 3

	: ${EXITVAL:=0}

	EXITVAL=$((${EXITVAL:-0} + 1))

	if [ "${actual}" != "${expected}" ]; then
		aecho FAIL "${lineinfo}" "${expected}" "${actual}" "$@"
		exit ${EXITVAL}
	fi
	aecho OK "${lineinfo}" #"${msg}: expected: '${expected}', actual: '${actual}'"

	return 0

}
alias assert='_assert "$0:$LINENO"'

_assert_not() {
	local -; set +x
	[ $# -ge 3 ] || eargs assert_not lineinfo notexpected actual msg
	local lineinfo="$1"
	local notexpected="$2"
	local actual="$3"
	shift 3

	: ${EXITVAL:=0}

	EXITVAL=$((${EXITVAL:-0} + 1))

	if [ "${actual}" = "${notexpected}" ]; then
		aecho FAIL "${lineinfo}" "!${notexpected}" "${actual}" "$@"
		exit ${EXITVAL}
	fi
	aecho OK "${lineinfo}" # "${msg}: notexpected: '${notexpected}', actual: '${actual}'"

	return 0

}
alias assert_not='_assert_not "$0:$LINENO"'

_assert_list() {
	local lineinfo="$1"
	local expected_name="$2"
	local actual_name="$3"
	local reason="$4"
	local have_tmp=$(mktemp -t actual.${actual_name})
	local expected_tmp=$(mktemp -t expected.${expected_name})
	local ret=0
	local expected actual

	getvar "${expected_name}" expected || expected="null"
	getvar "${actual_name}" actual || actual="null"

	echo "${expected}" |
	    tr ' ' '\n' | env LC_ALL=C sort |
            sed -e '/^$/d' > "${expected_tmp}"
	echo "${actual}" |
	    tr ' ' '\n' | env LC_ALL=C sort |
	    sed -e '/^$/d' > "${have_tmp}"
	cmp -s "${have_tmp}" "${expected_tmp}" || ret=$?
	if [ "${ret}" -ne 0 ]; then
		diff -u "${expected_tmp}" "${have_tmp}" >&2
	fi

	rm -f "${have_tmp}" "${expected_tmp}"
	if [ "${ret}" -ne 0 ]; then
		aecho FAIL "${lineinfo}" "${reason}"
		exit ${EXITVAL}
	fi
	aecho OK "${lineinfo}" #"${msg}: expected: '${expected}', actual: '${actual}'"
}
alias assert_list='_assert_list "$0:$LINENO"'


_assert_ret() {
	local lineinfo="$1"
	local expected="$2"
	shift 2
	local ret

	ret=0
	"$@" || ret=$?
	_assert "${lineinfo}" "${expected}" "${ret}" "Bad exit status: $@"
}
alias assert_ret='_assert_ret "$0:$LINENO"'

_assert_ret_not() {
	local lineinfo="$1"
	local expected="$2"
	shift 2
	local ret

	ret=0
	"$@" || ret=$?
	_assert_not "${lineinfo}" "${expected}" "${ret}" "Bad exit status: $@"
}
alias assert_ret_not='_assert_ret_not "$0:$LINENO"'

_assert_out() {
	local lineinfo="$1"
	local expected="$2"
	shift 2
	local out

        _assert "${lineinfo}" "${expected}" "$("$@")" "Bad output: $@"
}
alias assert_out='_assert_out "$0:$LINENO"'

aecho() {
	local -; set +x
	[ $# -ge 2 ] || eargs aecho result lineinfo expected actual msg
	local result="$1"
	local lineinfo="$2"
	local mypid

	: ${mypid:=$(sh -c 'echo $PPID')}

	if [ "$#" -gt 3 ]; then
		# Failure
		local expected="$3"
		local actual="$4"
		local INDENT
		shift 4
		INDENT=">>   "
		printf "%d> %-4s %s: %s\n${INDENT}expected '%s'\n${INDENT}actual '%s'\n" \
			"${mypid}" "${result}" "${lineinfo}" \
			"$(echo "$@" | cat -ev | sed '2,$s,^,	,')" \
			"$(echo "${expected}" | cat -ev | sed '2,$s,^,	,')" \
			"$(echo "${actual}" | cat -ev | sed '2,$s,^,	,')"
	elif [ "$#" -eq 3 ]; then
		printf "> %-4s %s: %s\n" "${result}" "${lineinfo}" "${3}"
	else
		printf "%d> %-4s %s\n" "${mypid}" "${result}" "${lineinfo}"
	fi >&2
}

rm() {
	local arg

	for arg in "$@"; do
		[ "${arg}" = "/" ] && err 99 "Tried to rm /"
		[ "${arg%/}" = "/COPYRIGHT" ] && err 99 "Tried to rm /*"
		[ "${arg%/}" = "/bin" ] && err 99 "Tried to rm /*"
	done

	command rm "$@"
}

_err() {
	local status="$1"
	shift
	echo "Error: $@" >&2
	exit ${status}
}
if ! type err >/dev/null 2>&1; then
	alias err=_err
fi
