# Note: this script will require BinaryBuilder.jl v0.3.0 or greater
using BinaryBuilder, Pkg
name = "ITKIOWrapper"
version = v"2.0.0"
# Collection of sources required to build ITKWrapper
sources = [
    DirectorySource("./src"),
]
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)
#needed for libjulia_platforms and julia_versions
include("../../L/libjulia/common.jl")

#filter julia versions to include only Julia >= 1.10 for LTS
julia_versions = filter(v-> v >= v"1.10", julia_versions)

# Bash recipe for building across all platforms
script = raw"""
export CXXFLAGS="-I${includedir}/julia $CXXFLAGS"
export CFLAGS="-I${includedir}/julia $CFLAGS"
mkdir -p build/

# Different CMake configuration for macOS
if [[ "${target}" == *-apple-* ]]; then
    cmake -B build -S . \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DBUILD_SHARED_LIBS:BOOL=ON \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=10.10
else
    cmake -B build -S . \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DBUILD_SHARED_LIBS:BOOL=ON \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
fi

cmake --build build --parallel ${nproc}
cmake --install build
install_license /usr/share/licenses/MIT
"""

# These are the platforms we will build for by default
platforms = vcat(libjulia_platforms.(julia_versions)...)
# Filter platforms
filter!(p -> !(arch(p) == "i686"), platforms)
filter!(!Sys.isfreebsd, platforms)
filter!(p -> !(arch(p) == "x86_64" && libc(p) == "musl"), platforms)
filter!(p -> !(arch(p) == "riscv64"), platforms)

# Expand C++ string ABI platforms
platforms = expand_cxxstring_abis(platforms)
# The products that we will ensure are always built
products = [
    LibraryProduct("libITKIOWrapper", :libITKIOWrapper),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="Eigen_jll", uuid="bc6bbf8a-a594-5541-9c57-10b0d0312c70")),
    Dependency(PackageSpec(name="ITK_jll", uuid="3324d3a8-621a-5aaa-97fa-c3bc8dfc0481"); compat="5.3.1"),
    Dependency(PackageSpec(name="libcxxwrap_julia_jll", uuid="3eaa8342-bff7-56a5-9981-c04077f7cee7"); compat = "0.13.2"),
    BuildDependency(PackageSpec(name="libjulia_jll", uuid="5ad3ddd2-0711-543a-b040-befd59781bbf"))
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.10", preferred_gcc_version=v"8.1.0",
preferred_llvm_version=v"13.0.1")

