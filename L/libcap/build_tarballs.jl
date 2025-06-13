# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libcap"
version = v"2.76"

# Collection of sources required to build libcap
sources = [
    ArchiveSource("https://mirrors.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-$(version.major).$(version.minor).tar.xz",
                  "629da4ab29900d0f7fcc36227073743119925fd711c99a1689bbf5c9b40c8e6f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libcap-*/

make -j${nproc}
make install DESTDIR=${prefix} prefix=/ lib=lib
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
# Only Linux is supported.
platforms = supported_platforms(; exclude=!Sys.islinux)

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
               julia_compat="1.6", preferred_gcc_version=v"8")
# GCC bump for an objcopy with --dump-sections support
