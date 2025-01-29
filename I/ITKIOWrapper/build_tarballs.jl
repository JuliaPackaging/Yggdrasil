# Note: this script will require BinaryBuilder.jl v0.3.0 or greater
using BinaryBuilder, Pkg
name = "ITKIOWrapper"
version = v"1.0.0"  # Update this to your package version

# Collection of sources required to build ITKWrapper
sources = [
    DirectorySource("./src"),
]

#needed for libjulia_platforms and julia_versions
include("../../L/libjulia/common.jl")

# Bash recipe for building across all Platforms
script = raw"""
export CXXFLAGS="-I${includedir}/julia $CXXFLAGS"
export CFLAGS="-I${includedir}/julia $CFLAGS"
mkdir -p build/
cmake -B build -S . \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_SHARED_LIBS:BOOL=ON
cmake --build build --parallel ${nproc}
cmake --install build
install_license /usr/share/licenses/MIT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = vcat(libjulia_platforms.(julia_versions)...)

#Filtering all the platforms, that ITK filters
filter!(p -> !(arch(p) == "i686"), platforms)
filter!(!Sys.isfreebsd, platforms)
filter!(p -> !(arch(p) == "x86_64" && libc(p) == "musl"), platforms)
filter!(p -> !(arch(p) == "riscv64"), platforms)
filter!(!Sys.iswindows, platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libITKIOWrapper", :libITKIOWrapper),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="Eigen_jll", uuid="bc6bbf8a-a594-5541-9c57-10b0d0312c70")),
    Dependency("ITK_jll"; compat="5.3.1"),
    Dependency("libcxxwrap_julia_jll"; compat = "0.13.2"),
    BuildDependency(PackageSpec(name="libjulia_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
    julia_compat="1.6", 
    preferred_gcc_version=v"8.1.0"
)
