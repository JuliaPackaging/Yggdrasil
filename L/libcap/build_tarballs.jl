# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libcap"
version = v"2.51"

# NOTE: v2.52 and higher requires objcopy with --dump-sections support
# (but also doesn't require -std=c99 anymore, so remove that below when upgrading)

# Collection of sources required to build libcap
sources = [
    ArchiveSource("https://mirrors.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-$(version.major).$(version.minor).tar.gz",
                  "f146cf1fa282483673df969b76ccd392697b903ac27ab7924c0fda103f5a0d26")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libcap-*/

make -j${nproc} BUILD_CC=${BUILD_CC} COPTS="-O2 -std=c99"
make install DESTDIR=${prefix} prefix=/ lib=lib
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = [p for p in supported_platforms() if Sys.islinux(p)]

# The products that we will ensure are always built
products = [
    LibraryProduct("libcap", :libcap),
    FileProduct("include/sys/capability.h", :capability_h),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
