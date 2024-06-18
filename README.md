About
-----

This project is a fork of
[poudriere](https://github.com/freebsd/poudriere).

FreeBSD port
[here](https://github.com/dsh2dsh/freebsd-ports/tree/master/ports-mgmt/poudriere-devel)

Changes from upstream:

  * Better reuse of prebuilded FreeBSD packages.

    Fetch packages after removing what we need to rebuild, not before that. See
    PR [1148](https://github.com/freebsd/poudriere/pull/1148).

  * Speedup building by rebuilding only changed ports.

    Don't rebuild recursively full chain of dependencies, rebuild only changed
    dependencies. Without this change poudriere rebuild changed ports, ports
    with changed dependencies and ports with dependencies with changed
    dependencies. For instance:

    ```
    Deleting vulkan-loader-1.3.273.pkg: new version: 1.3.274
    Deleting ffmpeg-6.1_1,1.pkg: missing dependency: vulkan-loader-1.3.273
    Deleting firefox-121.0,2.pkg: missing dependency: ffmpeg-6.1_1,1
    ```

    `firefox-121.0,2` doesn't depend on `vulkan-loader-1.3.273`, but poudriere
    removes it too, because `ffmpeg-6.1_1,1` was removed.

    Now poudriere will remove `ffmpeg-6.1_1,1`, but keep `firefox-121.0,2`,
    because version of `ffmpeg` will not change after rebuilding and
    `firefox-121.0,2` will have valid dependencies. The same step now looks:

    ```
    Deleting vulkan-loader-1.3.273.pkg: new version: 1.3.274
    Keeping ffmpeg-6.1_1,1.pkg: missing dependency: vulkan-loader-1.3.273

    ... after processing dependencies

    Deleting ffmpeg-6.1_1,1: missing dependency
    ```

    As you can see it will not rebuild firefox and finish everything faster. See
    PR [1101](https://github.com/freebsd/poudriere/pull/1101).

  * Share go mod cache between builders and store downloaded modules in
    `DISTFILES_CACHE`.

    Original `poudriere` doesn't store downloaded go modules back to
    `DISTFILES_CACHE` and it means it downloads it again and again. Now
    `DISTFILES_CACHE` mounted directly into builder jails and used as is,
    without copying distfiles into a builder jail and back into
    `DISTFILES_CACHE`.

Welcome to poudriere!
---------------------

poudriere is a tool primarily designed to test package production on
FreeBSD. However, most people will find it useful to bulk build ports
for FreeBSD.

Its goals are to use modern facilities present in FreeBSD (such as ZFS,
jails), to be easy to use and to depend only on base.

Where is the documentation?
---------------------------

The canonical documentation is located at:

https://github.com/freebsd/poudriere/wiki

A copy of this documentation could be found in the doc directory.

You can also open the poudriere's manpage, located in the 8th section.

Support
-------

IRC:          #poudriere on EFNet
Mailing list: [freebsd-pkg@FreeBSD.org (lists.freebsd.org)](https://lists.freebsd.org/subscription/freebsd-pkg)

Getting started with poudriere
------------------------------

1. Install it by typing `./configure`, `make` and `make install` at the top-level directory
2. Copy `/usr/local/etc/poudriere.conf.sample` to `/usr/local/etc/poudriere.conf`
3. Edit it to suit your needs
4. `man poudriere`, search for `EXAMPLES`, read the [wiki](https://github.com/freebsd/poudriere/wiki)
5. Follow "bulk build of binary packages" steps
6. Enjoy your new fresh binary packages!

Build status
------------------------------

* [![Build Status](https://api.cirrus-ci.com/github/freebsd/poudriere.svg?branch=master)](https://cirrus-ci.com/github/freebsd/poudriere)
