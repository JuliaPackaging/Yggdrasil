# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libcap"
version = v"2.27"

# Collection of sources required to build libcap-ng
sources = [
    "https://mirrors.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-$(version.major).$(version.minor).tar.gz" =>
    "260b549c154b07c3cdc16b9ccc93c04633c39f4fb6a4a3b8d1fa5b8a9c3f5fe8",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libcap-*/

# GNU (not musl) 64-bit archs put their loader in `/lib64`
if [[ ${target} == *gnu* ]] && [[ ${nbits} == 64 ]]; then
    LOADER_DIR=lib64
else
    LOADER_DIR=lib
fi

make -j${nproc} BUILD_CC=${BUILD_CC}
make install DESTDIR=${prefix} prefix=/ lib=${LOADER_DIR} RAISE_SETFCAP=no
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = [p for p in supported_platforms() if p isa Linux]

# The products that we will ensure are always built
products = [
    LibraryProduct("libcap", :libcap),
    FileProduct("include/sys/capability.h", :capability_h),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
