# $FreeBSD: head/devel/libtextstyle/Makefile 503716 2019-06-08 09:55:01Z tijl $

# NOTE: before committing to this port, contact portmgr to arrange for an
# experimental ports run.  Untested commits may be backed out at portmgr's
# discretion.

PORTNAME=	libtextstyle
PORTREVISION=	0

COMMENT=	Text styling library

LICENSE=	GPLv3+
LICENSE_FILE=	${WRKSRC}/COPYING

.include "${.CURDIR}/../gettext/Makefile.common"

USES=		iconv libtool ncurses tar:xz
USE_LDCONFIG=	yes

GNU_CONFIGURE=	yes
CONFIGURE_ARGS=	--with-libncurses-prefix=${NCURSESBASE}
INSTALL_TARGET=	install-strip
TEST_TARGET=	check
WRKSRC_SUBDIR=	libtextstyle

CFLAGS+=	-Wno-error=incompatible-function-pointer-types

INFO=		libtextstyle

OPTIONS_DEFINE=	DOCS

.include <bsd.port.mk>
