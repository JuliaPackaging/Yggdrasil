using BinaryBuilder, Pkg

# Apple's diskdev_cmds, Linux port ("540.1.linux3"), as shipped by Debian and
# Ubuntu under the name hfsprogs. We build only newfs_hfs, the HFS/HFS+
# formatter that Debian installs as mkfs.hfsplus.
name = "hfsprogs"
version = v"540.1.3"   # upstream version string is 540.1.linux3

sources = [
    # Pristine Apple tarball. Same file Debian ships as hfsprogs_540.1.linux3.orig.tar.gz
    # (identical sha256); this mirror is the one Mozilla pins in taskcluster.
    ArchiveSource(
        "https://src.fedoraproject.org/repo/pkgs/hfsplus-tools/diskdev_cmds-540.1.linux3.tar.gz/0435afc389b919027b69616ad1b05709/diskdev_cmds-540.1.linux3.tar.gz",
        "b01b203a97f9a3bf36a027c13ddfc59292730552e62722d690d33bd5c24f5497"),
    # Debian packaging: the patch series (needed to build with GCC) and the
    # APSL-2.0 license text, which the upstream tarball does not contain.
    ArchiveSource(
        "http://archive.ubuntu.com/ubuntu/pool/universe/h/hfsprogs/hfsprogs_540.1.linux3-5build3.debian.tar.xz",
        "ac4171210d6174d6071988e850beb447e1c60bdf0f17cd7656e27690179b2042"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/diskdev_cmds-540.1.linux3

# Debian's series, in order: remove the Blocks C extension (upstream's
# Makefiles hardcode `clang -fblocks` and build a BlocksRuntime), fix stdarg
# on ARM, swap <sys/sysctl.h> for the Linux one, use CURDIR instead of PWD,
# restore HFS-standard support, and dispatch on argv[0].
for p in $(cat ${WORKSPACE}/srcdir/debian/patches/series); do
    atomic_patch -p1 ${WORKSPACE}/srcdir/debian/patches/${p}
done

# hfs_format.h pulls in <uuid/uuid.h> only for the uuid_string_t typedef,
# which include/missing.h already provides. Nothing links against libuuid,
# so drop the include rather than take a dependency on it.
sed -i '/#include <uuid\/uuid.h>/d' include/hfs/hfs_format.h

# Debian patch 0003 adds <linux/sysctl.h> unconditionally, but every sysctl()
# and sysctlbyname() call site sits inside `#if !LINUX`. The include is dead
# weight on Linux and fatal everywhere else. Mozilla drops it the same way.
sed -i '/sysctl\.h/d' newfs_hfs.tproj/makehfs.c

if [[ "${target}" == *freebsd* ]]; then
    # include/missing.h defines __APPLE_API_PRIVATE, and on FreeBSD
    # <sys/mount.h> chains through <sys/ucred.h> to <bsm/audit.h>, which reacts
    # to that macro by including <mach/port.h> -- a Darwin header the sysroot
    # has no reason to ship. The macro gates one block in hfs_format.h holding
    # the private metadata-folder names, the iNode/dir_/temp prefixes and the
    # link xattr constants, none of which newfs_hfs references. Note the same
    # macro is also set in include/sys/appleapiopts.h; that copy is not the one
    # that reaches this code path, so both have to go.
    sed -i '/^#define __APPLE_API_PRIVATE$/d' include/missing.h include/sys/appleapiopts.h
fi

if [[ "${target}" == *-musl* ]]; then
    # The sources declare every prototype through the 4.4BSD __P() macro, which
    # glibc, Darwin and FreeBSD still provide in <sys/cdefs.h>. musl ships no
    # <sys/cdefs.h> at all, so __P survives into the token stream and every
    # declaration is a syntax error. Force-include a definition ahead of the
    # translation unit rather than patching ~40 declarations.
    mkdir -p compat
    cat > compat/cdefs_shim.h <<'EOF'
#ifndef HFSPROGS_COMPAT_CDEFS_H
#define HFSPROGS_COMPAT_CDEFS_H
#ifndef __P
#define __P(protos) protos
#endif
#endif
EOF
    export CFLAGS="${CFLAGS} -include ${PWD}/compat/cdefs_shim.h"
fi

if [[ "${target}" != *-linux-* ]]; then
    # We keep -DLINUX=1 on Darwin and FreeBSD too. The `#else` branch is
    # Apple's original code, and its device-size probe has no S_ISREG case at
    # all: it goes straight to ioctl(DKIOCGETBLOCKSIZE), which fails on a plain
    # file (and DKIOC* does not exist on FreeBSD in the first place). Since
    # formatting image files is the whole point here, we want the LINUX path,
    # and supply the two glibc headers newfs_hfs assumes. Both shims are pure
    # compiler builtins, so the same pair serves either target.
    mkdir -p compat

    cat > compat/endian.h <<'EOF'
#ifndef HFSPROGS_COMPAT_ENDIAN_H
#define HFSPROGS_COMPAT_ENDIAN_H
/* hfs_endian.h tests the bare BYTE_ORDER names; missing.h tests the
   double-underscore ones. Define both: if BYTE_ORDER were left undefined,
   `#if BYTE_ORDER == BIG_ENDIAN` silently evaluates 0 == 0 and the swaps
   become no-ops, producing byte-reversed volumes rather than a build error. */
#ifndef __LITTLE_ENDIAN
#define __LITTLE_ENDIAN __ORDER_LITTLE_ENDIAN__
#endif
#ifndef __BIG_ENDIAN
#define __BIG_ENDIAN __ORDER_BIG_ENDIAN__
#endif
#ifndef __BYTE_ORDER
#define __BYTE_ORDER __BYTE_ORDER__
#endif
#ifndef LITTLE_ENDIAN
#define LITTLE_ENDIAN __LITTLE_ENDIAN
#endif
#ifndef BIG_ENDIAN
#define BIG_ENDIAN __BIG_ENDIAN
#endif
#ifndef BYTE_ORDER
#define BYTE_ORDER __BYTE_ORDER
#endif
#endif
EOF

    # Compiler builtins rather than <libkern/OSByteOrder.h>: missing.h defines
    # its own OSSwapBigToHostInt* macros, which would clash with libkern's.
    cat > compat/byteswap.h <<'EOF'
#ifndef HFSPROGS_COMPAT_BYTESWAP_H
#define HFSPROGS_COMPAT_BYTESWAP_H
#define bswap_16(x) __builtin_bswap16(x)
#define bswap_32(x) __builtin_bswap32(x)
#define bswap_64(x) __builtin_bswap64(x)
#endif
EOF

    # The Makefile uses `CFLAGS +=`, so the environment value is the base and
    # compat/ lands ahead of include/. Never pass CFLAGS on the make command
    # line: that would override the += and drop -DLINUX=1 along with it.
    export CFLAGS="${CFLAGS} -I${PWD}/compat"
fi

# SUBDIRS drops fsck_hfs on every platform, which keeps /proc/self/mounts,
# <mntent.h> and the O_EXLOCK divergence out of the build entirely. Overriding
# it on the command line leaves the top-level CFLAGS intact.
#
# LDFLAGS is overridden because the Makefile hardcodes `LDFLAGS :=
# -Wl,--build-id`, which is GNU ld only and ld64 rejects. A command-line
# assignment beats the := and reaches submakes.
make -j${nproc} CC="${CC}" LDFLAGS="${LDFLAGS}" SUBDIRS="newfs_hfs.tproj"

install -Dm755 newfs_hfs.tproj/newfs_hfs ${bindir}/newfs_hfs

install_license ${WORKSPACE}/srcdir/debian/copyright
"""

# Everything BinaryBuilder supports except Windows: HFS+ is a Unix filesystem
# and the port has no Windows story at all. This is the same platform set the
# libdmg_hfsplus recipe uses.
platforms = filter!(!Sys.iswindows, supported_platforms())

products = [
    ExecutableProduct("newfs_hfs", :newfs_hfs),
]

# newfs_hfs links -lcrypto; it only uses the SHA1 routines.
dependencies = [
    Dependency("OpenSSL_jll"),
]

# GCC 6 is the first toolchain BinaryBuilder pairs with glibc 2.17. The default
# (4.8) gives glibc 2.12, against which OpenSSL_jll's libcrypto.so fails to
# link: it needs memcpy@2.14, getauxval@2.16, clock_gettime@2.17 and
# secure_getenv@2.17. Platforms whose own floor is higher (riscv64 needs 14,
# aarch64-freebsd needs 9) are unaffected; this is only a preference.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.6", preferred_gcc_version = v"6")
