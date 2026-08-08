# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "qkrylov"
version = v"0.0.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sjp95/qkrylov.git", "c401ad20389eacb6af0df12e2d2d8f0a73817732")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/qkrylov*

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      -DQKRYLOV_BUILD_TESTS=OFF \
      -DQKRYLOV_BUILD_PYTHON=OFF \
      ..

make -j${nproc}
make install
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libqkrylov", :libqkrylov)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.10", preferred_gcc_version=v"11")
