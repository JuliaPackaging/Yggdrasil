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
atomic_patch -p1 ../patches/tests-missing-headers.patch
if [[ "${target}" == *-mingw* ]]; then
    # Apply patch from
    # https://github.com/msys2/MINGW-packages/blob/66c0195ad84836161c48797241a1c7611ac4a435/mingw-w64-zeromq/001-testutil_different_signedness-fix.patch
    atomic_patch -p1 ../patches/001-testutil_different_signedness-fix.patch
elif [[ "${target}" == *86*-linux-musl* ]]; then
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
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libzmq", :libzmq),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("libsodium_jll")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
