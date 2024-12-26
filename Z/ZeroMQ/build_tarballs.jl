using BinaryBuilder

name = "ZeroMQ"
version = v"4.3.5"

# Collection of sources required to build ZMQ
sources = [
    GitSource("https://github.com/zeromq/libzmq.git", "622fc6dde99ee172ebaa9c8628d85a7a1995a21d"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libzmq
if [[ "${target}" == *86*-linux-musl* ]]; then
    # Fix bug in Musl C library, see
    # https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/387
    atomic_patch -d /opt/${target}/lib/gcc/${target}/*/include -p0 $WORKSPACE/srcdir/patches/mm_malloc.patch
fi
sh autogen.sh
./configure --prefix=$prefix \
    --build=${MACHTYPE} \
    --host=${target} \
    --without-docs \
    --enable-drafts \
    --with-libsodium \
    --disable-libunwind \
    --disable-perf \
    --disable-Werror \
    --disable-eventfd \
    --without-gcov \
    --disable-static \
    CXXFLAGS="-O2 -fms-extensions"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libzmq", :libzmq),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libsodium_jll")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6")

# Build trigger: 1
