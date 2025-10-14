/*-
 * Copyright (c) 2014 Bryan Drewery <bdrewery@FreeBSD.org>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer
 *    in this position and unchanged.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR(S) ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR(S) BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <err.h>
#include <stdlib.h>
#include <stdio.h>
#include <sysexits.h>
#include <unistd.h>

#ifdef SHELL
#define main renamecmd
#include "bltin/bltin.h"
#include "helpers.h"
#endif

static void
usage(void)
{
	errx(EX_USAGE, "Usage: rename [-qv] src dst");
}

/**
 * Just call rename(2) on the params. This is a replacement for mv(1)
 * to both lower overhead and to support mv -h, which is not in 8.x or
 * 9.1, to rename a symlink and not move it.
 * It is also to purposely fail on EXDEV.
 */
int
main(int argc, char **argv)
{
	int ch, qflag, vflag;

	qflag = vflag = 0;
	while ((ch = getopt(argc, argv, "qv")) != -1) {
		switch (ch) {
		case 'q':
			qflag = 1;
			break;
		case 'v':
			vflag = 1;
			break;
		default:
			usage();
			break;
		}
	}
	argc -= optind;
	argv += optind;

	if (argc != 2)
		usage();

	if (rename(argv[0], argv[1])) {
		if (qflag == 0)
			err(EXIT_FAILURE, "%s -> %s", argv[0], argv[1]);
		else
			exit(EXIT_FAILURE);
	} else if (vflag)
		printf("%s -> %s\n", argv[0], argv[1]);

	return (0);
}
