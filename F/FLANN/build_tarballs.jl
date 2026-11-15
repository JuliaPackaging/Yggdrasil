# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FLANN"
version = v"1.9.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/flann-lib/flann.git", "c50f296b0b27e14667d272b37acc63f949b305c4")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/flann*
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:${prefix}/libdata/pkgconfig:${prefix}/bin/pkgconfig

cmake -B build -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_EXAMPLES=OFF \
      -DBUILD_TESTS=OFF \
      -DBUILD_DOC=OFF \
      -DBUILD_PYTHON_BINDINGS=OFF \
      -DBUILD_MATLAB_BINDINGS=OFF \
      -DCMAKE_CXX_STANDARD=11

cmake --build build -j${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libflann_cpp", :libflann_cpp),
    LibraryProduct("libflann", :libflann)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms))
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms))
    Dependency("Lz4_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.10")
