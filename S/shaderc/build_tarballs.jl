# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Shaderc"
version = v"2022.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/google/shaderc.git", "e4722b0ad49ee60c143d43baae8390f75ba27d2d")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/shaderc*/
./utils/git-sync-deps 
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DSHADERC_SKIP_TESTS=1 \
    -DSHADERC_SKIP_EXAMPLES=1 \
    -DSHADERC_SKIP_COPYRIGHT_CHECK=1 \
    -S .. \
    -B .
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libshaderc_shared", :libshaderc_shared),
    LibraryProduct("libSPIRV-Tools-shared", :libSPIRV_Tools_shared),
    ExecutableProduct("spirv-dis", :spirv_dis),
    ExecutableProduct("spirv-lint", :spirv_lint),
    ExecutableProduct("spirv-opt", :spirv_opt),
    ExecutableProduct("glslangValidator", :glslangValidator),
    ExecutableProduct("spirv-cfg", :spirv_cfg),
    ExecutableProduct("spirv-link", :spirv_link),
    ExecutableProduct("glslc", :glslc),
    ExecutableProduct("spirv-remap", :spirv_remap),
    ExecutableProduct("spirv-val", :spirv_val),
    ExecutableProduct("spirv-reduce", :spirv_reduce),
    ExecutableProduct("spirv-as", :spirv_as)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"11.1.0")
