# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MuesliMaterials"
version = v"1.16.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://bitbucket.org/ignromero/muesli.git", "02f64b4ce84c2b69bea2f31217b62f522d676b0c")
    DirectorySource("bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/muesli

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cmakesupport.patch

cmake -B builddir -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release \
                  -DBLAS_LIBRARIES="${libdir}/libopenblas.${dlext}" -DLAPACK_LIBRARIES="${libdir}/libopenblas.${dlext}" 
cmake --build builddir --parallel ${nprocs}
cmake --install builddir

"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmuesli", :libmuesli)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenBLAS32_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")
