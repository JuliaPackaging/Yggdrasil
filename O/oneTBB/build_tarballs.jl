# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oneTBB"
version = v"2021.2.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/oneapi-src/oneTBB.git",
              # Note: this isn't actually 2021.2.1 (there is no such versions at
              # the moment), this seems to be the revision where most platforms
              # are successful
              "9e15720bc7744f85dff611d34d65e9099e077da4"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/oneTBB/

# Adapt patch from
# https://github.com/oneapi-src/oneTBB/pull/203
atomic_patch -p1 ../patches/musl.patch

mkdir build && cd build/
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DTBB_TEST=OFF \
    -DTBB_EXAMPLES=OFF \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))
# Windows with MinGW at the moment doesn't work, but it may change in the near
# future, watch out <https://github.com/oneapi-src/oneTBB/pull/351>. See also
# <https://stackoverflow.com/q/67572880/2442087>.
filter!(!Sys.iswindows, platforms)
# Disable platforms unlikely to work
filter!(p -> arch(p) ∉ ("armv6l", "armv7l"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libtbbmalloc", :libtbbmalloc),
    LibraryProduct("libtbbmalloc_proxy", :libtbbmalloc_proxy),
    LibraryProduct("libtbb", :libtbb),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
