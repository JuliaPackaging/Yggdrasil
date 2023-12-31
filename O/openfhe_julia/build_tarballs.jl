# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "openfhe_julia"
version = v"0.1.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sloede/openfhe-julia.git",
              "e4be04ac212508869efb140d55fdf622181e79ee"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/openfhe-julia/

mkdir build && cd build

cmake .. \
  -DCMAKE_INSTALL_PREFIX=$prefix \
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
  -DCMAKE_BUILD_TYPE=Release \
  -DJulia_PREFIX=$prefix

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)

# We cannot build with musl since OpenFHE requires the `execinfo.h` header for `backtrace`
platforms = filter(p -> libc(p) != "musl", platforms)

# PowerPC and 32-bit x86 platforms are not supported by OpenFHE
platforms = filter(p -> arch(p) != "i686", platforms)
platforms = filter(p -> arch(p) != "powerpc64le", platforms)

# Expand C++ string ABIs since we use std::string
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libopenfhe_julia", :libopenfhe_julia),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(;name="libjulia_jll", version=v"1.10.8")),
    Dependency(PackageSpec(name="libcxxwrap_julia_jll", uuid="3eaa8342-bff7-56a5-9981-c04077f7cee7")),
    Dependency(PackageSpec(name="OpenFHE_jll", uuid="a2687184-f17b-54bc-b2bb-b849352af807")),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"10.2.0")
