# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ImageStreamIO"
version = v"1.0.3-beta"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/milk-org/ImageStreamIO.git", "c4b3c531f4653f3b570345f43b2686cd25af0db8")
]

# Bash recipe for building across all platforms
script = raw"""
cd ImageStreamIO
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [Platform("x86_64", "linux")]

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libImageStreamIO", :libimagestreamio)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CMake_jll", uuid="3f4e10e2-61f2-5801-8945-23b9d642d0e6"))
    Dependency(PackageSpec(name="CUDA_jll", uuid="e9e359dc-d701-5aa8-82ae-09bbf812ea83"))
    Dependency(PackageSpec(name="CFITSIO_jll", uuid="b3e40c51-02ae-5482-8a39-3ace5868dcf4"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", allow_unsafe_flags=true)
