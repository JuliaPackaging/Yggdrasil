using BinaryBuilder

name = "ZeroMQ"
version = v"4.3.2"

# Collection of sources required to build ZMQ
sources = [
    GitSource("https://github.com/zeromq/libzmq.git", "a84ffa12b2eb3569ced199660bac5ad128bff1f0"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libzmq
if [[ "${target}" == *-mingw* ]]; then
    # Apply patch from
    # https://github.com/msys2/MINGW-packages/blob/350ace4617661a4df7b9474c573b08325fa716c3/mingw-w64-zeromq/001-mingw-__except-fixes.patch
    atomic_patch -p1 ../patches/001-mingw-__except-fixes.patch
elif [[ "${target}" == *86*-linux-musl* ]]; then
    pushd /opt/${target}/lib/gcc/${target}/*/include
    # Fix bug in Musl C library, see
    # https://github.com/JuliaPackaging/BinaryBuilder.jl/issues/387
    atomic_patch -p0 $WORKSPACE/srcdir/patches/mm_malloc.patch
    popd
fi
sh autogen.sh
./configure --prefix=$prefix \
    --host=${target} \
    --without-docs \
    --enable-drafts \
    --disable-libunwind \
    --disable-perf \
    --disable-Werror \
    --disable-eventfd \
    --without-gcov \
    --disable-curve-keygen \
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
dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
