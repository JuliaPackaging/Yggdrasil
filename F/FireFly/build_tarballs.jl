# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FireFly"
version = v"2.0.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.com/firefly-library/firefly.git", "f0b0b316790fbe23b88dd7b759220944bc77302d")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir $WORKSPACE/srcdir/FireFly-build
cd $WORKSPACE/srcdir/FireFly-build/

cmake -DWITH_FLINT=true \
    -DCUSTOM=true \
    -DWITH_JEMALLOC=true \
    -DWITH_MPI=true \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ${WORKSPACE}/srcdir/firefly || (echo "Ignored known CMake errors.")

cmake --build . -j${nproc}
cmake --build . -t install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows)
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libfirefly", :libfirefly)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="FLINT_jll", uuid="e134572f-a0d5-539d-bddf-3cad8db41a82"))
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"))
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="MPICH_jll", uuid="7cb0a576-ebde-5e09-9194-50597f1243b4"))
    Dependency(PackageSpec(name="jemalloc_jll", uuid="454a8cc1-5e0e-5123-92d5-09b094f0e876"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6",
    preferred_gcc_version = v"5.2.0" # for std=c++14
)
