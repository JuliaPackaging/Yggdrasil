# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "vmecpp_julia"
version = v"0.4.11"

# Julia versions to support
# Note: Julia 1.12 temporarily disabled due to BinaryBuilder/Pkg compatibility issue
julia_versions = [v"1.10", v"1.11"]
julia_compat = join(map(julia_versions) do v "~$(v.major).$(v.minor)" end, ", ")

# Collection of sources required to build vmecpp_julia
sources = [
    # Main vmecpp repository
    GitSource("https://github.com/proximafusion/vmecpp.git",
              "04f16f531ead8995b1f4a5a5f92024e82f83f86a"),  # v0.4.11

    # Eigen 3.4.0 (header-only)
    GitSource("https://gitlab.com/libeigen/eigen.git",
              "3147391d946bb4b6c68edd901f2add6ac1f31f8c",  # 3.4.0
              unpack_target="eigen"),

    # Abseil-cpp (specific commit used by vmecpp)
    GitSource("https://github.com/abseil/abseil-cpp.git",
              "4447c7562e3bc702ade25105912dce503f0c4010",
              unpack_target="abseil-cpp"),

    # nlohmann_json v3.11.3
    ArchiveSource("https://github.com/nlohmann/json/releases/download/v3.11.3/json.tar.xz",
                  "d6c65aca6b1ed68e7a182f4757257b107ae403032760ed6ef121c9d55e81757d",
                  unpack_target="nlohmann_json"),

    # abscab-cpp
    GitSource("https://github.com/jonathanschilling/abscab-cpp.git",
              "5cfa473b90aab06d7f70d986da0c46c46c1ebe9c",
              unpack_target="abscab-cpp"),

    # indata2json
    GitSource("https://github.com/jonathanschilling/indata2json.git",
              "f59e3ddd66486b63536f141a786d39c23d654c77",
              unpack_target="indata2json"),

    # Julia wrapper sources (bundled)
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

# Debug: List source directories
echo "Listing srcdir contents:"
ls -la

# ============================================
# Step 1: Build Abseil as static libraries
# ============================================
echo "Building Abseil..."

# Patch Abseil to remove architecture-specific flags that BinaryBuilder doesn't allow
# These flags are in GENERATED_AbseilCopts.cmake for hardware AES acceleration
sed -i 's/"-march=armv8-a+crypto"//g' abseil-cpp/abseil-cpp/absl/copts/GENERATED_AbseilCopts.cmake
sed -i 's/"-maes"//g' abseil-cpp/abseil-cpp/absl/copts/GENERATED_AbseilCopts.cmake
sed -i 's/"-msse4.1"//g' abseil-cpp/abseil-cpp/absl/copts/GENERATED_AbseilCopts.cmake
sed -i 's/"-mfpu=neon"//g' abseil-cpp/abseil-cpp/absl/copts/GENERATED_AbseilCopts.cmake

mkdir -p abseil-build && cd abseil-build
cmake ../abseil-cpp/abseil-cpp \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_CXX_STANDARD=20 \
    -DABSL_PROPAGATE_CXX_STD=ON \
    -DABSL_BUILD_TESTING=OFF
make -j${nproc}
make install
cd ..

# ============================================
# Step 2: Build vmecpp core (static library)
# ============================================
echo "Building vmecpp core..."

# Patch vmecpp CMakeLists.txt to remove Python bindings (pybind11)
# We only need vmecpp_core, not the Python module
sed -i '/FetchContent_Declare.*pybind11/,/FetchContent_MakeAvailable.*pybind11/d' vmecpp/CMakeLists.txt
sed -i '/pybind11_add_module/,/install.*_vmecpp/d' vmecpp/CMakeLists.txt

mkdir -p vmecpp-build && cd vmecpp-build

# Configure vmecpp with vendored dependencies
cmake ../vmecpp \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=20 \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DFETCHCONTENT_SOURCE_DIR_EIGEN3=${WORKSPACE}/srcdir/eigen \
    -DFETCHCONTENT_SOURCE_DIR_NLOHMANN_JSON=${WORKSPACE}/srcdir/nlohmann_json/json \
    -DFETCHCONTENT_SOURCE_DIR_ABSEIL=${WORKSPACE}/srcdir/abseil-cpp \
    -DFETCHCONTENT_SOURCE_DIR_ABSCAB=${WORKSPACE}/srcdir/abscab-cpp \
    -DFETCHCONTENT_SOURCE_DIR_INDATA2JSON=${WORKSPACE}/srcdir/indata2json \
    -DFETCHCONTENT_FULLY_DISCONNECTED=ON \
    -Dabsl_DIR=${prefix}/lib/cmake/absl

# Build only the core library (not Python bindings or standalone)
make -j${nproc} vmecpp_core
cd ..

# ============================================
# Step 3: Build Julia wrapper (shared library)
# ============================================
echo "Building Julia wrapper..."
mkdir -p julia-build && cd julia-build
cmake ../bundled \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=20 \
    -DJulia_PREFIX=${prefix} \
    -DVMECPP_SOURCE_DIR=${WORKSPACE}/srcdir/vmecpp \
    -DVMECPP_BUILD_DIR=${WORKSPACE}/srcdir/vmecpp-build \
    -DEIGEN_DIR=${WORKSPACE}/srcdir/eigen \
    -Dabsl_DIR=${prefix}/lib/cmake/absl
make -j${nproc}
make install

# Install license
install_license ${WORKSPACE}/srcdir/vmecpp/LICENSE
"""

# Platforms - use Yggdrasil's common.jl for proper Julia platform triplets
include("../../L/libjulia/common.jl")
platforms = reduce(vcat, libjulia_platforms.(julia_versions))

# Filter out unsupported platforms
filter!(p -> arch(p) != "armv7l", platforms)  # ARM32 often problematic
filter!(p -> arch(p) != "armv6l", platforms)  # Experimental
filter!(p -> !Sys.iswindows(p), platforms)    # Windows not supported yet
filter!(p -> !Sys.isfreebsd(p), platforms)    # FreeBSD not tested

# Expand C++ string ABIs
platforms = expand_cxxstring_abis(platforms)

# Products
products = [
    LibraryProduct("libvmecpp_julia", :libvmecpp_julia; dlopen_flags=[:RTLD_GLOBAL]),
]

# Dependencies
dependencies = [
    # Build dependencies
    BuildDependency("libjulia_jll"),

    # Runtime dependencies
    Dependency("libcxxwrap_julia_jll"; compat="~0.12"),
    Dependency("HDF5_jll"),
    Dependency("NetCDF_jll"),
    Dependency("OpenBLAS_jll"),
    Dependency("LLVMOpenMP_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version = v"10",  # C++20 support
               julia_compat)
