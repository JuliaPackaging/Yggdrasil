# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

# Include macOS SDK helper for using newer SDKs
include("../../platforms/macos_sdks.jl")

# Workarounds for Pkg.jl bugs with stdlibs
# See https://github.com/JuliaLang/Pkg.jl/issues/2942

# Delete OpenSSL_jll stdlib to avoid conflicts during dependency resolution
uuidopenssl = Base.UUID("458c3c95-2e84-50aa-8efc-19380b2a3a95")
delete!(Pkg.Types.get_last_stdlibs(v"1.12.0"), uuidopenssl)
delete!(Pkg.Types.get_last_stdlibs(v"1.13.0"), uuidopenssl)

# Workaround for haskey bug in Julia 1.12: Empty weakdeps from Pkg stdlib
# The bug is triggered when a stdlib (like Pkg) has weakdeps and gets resolved
# as part of the dependency graph. The code tries to call haskey(p.deps, name)
# where p.deps is a Vector{UUID} but the code expects a Dict.
# By emptying weakdeps, we avoid the buggy code path in Pkg.Operations.fixups_from_projectfile!
uuidpkg = Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f")
for v in [v"1.12.0", v"1.13.0"]
    stdlibs = Pkg.Types.get_last_stdlibs(v)
    if haskey(stdlibs, uuidpkg)
        empty!(stdlibs[uuidpkg].weakdeps)
    end
end

# Include libjulia common.jl to get julia_versions and libjulia_platforms
include("../../L/libjulia/common.jl")

# Filter to supported Julia versions (1.11 and 1.12)
filter!(v -> (v.major, v.minor) in [(1, 11), (1, 12)], julia_versions)

name = "vmecpp_julia"
version = v"0.4.11"

# julia_compat string for build_tarballs
julia_compat = libjulia_julia_compat(julia_versions)

# Collection of sources required to build vmecpp_julia
sources = [
    # Main vmecpp repository
    GitSource("https://github.com/proximafusion/vmecpp.git",
              "04f16f531ead8995b1f4a5a5f92024e82f83f86a"),  # v0.4.11

    # Abseil-cpp (vendored - cannot use abseil_cpp_jll due to C++20 requirement)
    # abseil_cpp_jll is built with C++14, vmecpp requires C++20 + static linking
    GitSource("https://github.com/abseil/abseil-cpp.git",
              "4447c7562e3bc702ade25105912dce503f0c4010",
              unpack_target="abseil-cpp"),

    # nlohmann_json v3.11.3 (vendored for FetchContent cmake integration)
    # vmecpp uses CMake FetchContent which needs the full source tree with CMakeLists.txt;
    # nlohmann_json_jll only provides headers without the cmake infrastructure
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

    # LIBSTELL (submodule of indata2json)
    GitSource("https://github.com/ORNL-Fusion/LIBSTELL.git",
              "92ac5c339b31e29d9d734c20eae3e7571de8f490",
              unpack_target="LIBSTELL"),

    # json-fortran (submodule of indata2json)
    GitSource("https://github.com/jonathanschilling/json-fortran.git",
              "954a46c32958ea7d15884351f9b7f3aa397001e7",
              unpack_target="json-fortran"),

    # Julia wrapper sources (bundled)
    # These are CxxWrap bindings for vmecpp. The upstream goal is to move these into
    # the vmecpp repository itself (https://github.com/proximafusion/vmecpp).
    # Currently maintained at: https://github.com/proximafusion/VMECPP.jl/tree/main/deps/src
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

# Clean up macOS resource fork files (._*) that can corrupt CMake modules
# These files end up in the Docker container and cause parse errors
find /usr/share/cmake -name '._*' -delete 2>/dev/null || true

# Debug: List source directories
echo "Listing srcdir contents:"
ls -la

# ============================================
# Step 0: Setup submodules that weren't cloned recursively
# ============================================
echo "Setting up indata2json submodules..."
# Debug: Show what's in the source directories
echo "Contents of LIBSTELL directory:"
ls -la LIBSTELL/
echo "Contents of json-fortran directory:"
ls -la json-fortran/

# LIBSTELL and json-fortran are submodules of indata2json
# With unpack_target, content is in nested directory (LIBSTELL/LIBSTELL, json-fortran/json-fortran)
# Remove any existing placeholder directories from the submodule declarations, then move our content
rm -rf indata2json/indata2json/LIBSTELL indata2json/indata2json/json-fortran
mv LIBSTELL/LIBSTELL indata2json/indata2json/LIBSTELL
mv json-fortran/json-fortran indata2json/indata2json/json-fortran

# List the indata2json directory to verify
echo "Contents of indata2json/indata2json:"
ls -la indata2json/indata2json/
echo "Contents of indata2json/indata2json/LIBSTELL:"
ls -la indata2json/indata2json/LIBSTELL/ || echo "LIBSTELL dir not found"
echo "Contents of indata2json/indata2json/LIBSTELL/Sources (should exist):"
ls -la indata2json/indata2json/LIBSTELL/Sources/ || echo "LIBSTELL/Sources dir not found"

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
# We only need vmecpp_core, not the Python module or indata2json executable
sed -i '/FetchContent_Declare.*pybind11/,/FetchContent_MakeAvailable.*pybind11/d' vmecpp/CMakeLists.txt
sed -i '/pybind11_add_module/,/install.*_vmecpp/d' vmecpp/CMakeLists.txt
# Also remove install target for indata2json (we only build vmecpp_core)
sed -i '/install.*TARGETS.*indata2json/d' vmecpp/CMakeLists.txt

mkdir -p vmecpp-build && cd vmecpp-build

# macOS: SDK 12.3 has full C++20 support, but we need to disable availability annotations
# since we're targeting deployment_target=10.15 but using features from SDK 12.3
MACOS_CXX_FLAGS=""
if [[ "${target}" == *-apple-* ]]; then
    echo "macOS detected: disabling availability annotations (using SDK 12.3 with deployment target 10.15)"
    MACOS_CXX_FLAGS="-D_LIBCPP_DISABLE_AVAILABILITY"
fi

# Configure vmecpp with vendored dependencies
# Note: FetchContent variable names use the EXACT name from FetchContent_Declare
# For packages with hyphens, CMake converts them to underscores in cache variables
# BUT we also need to try the hyphenated form for compatibility
cmake ../vmecpp \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=20 \
    -DCMAKE_CXX_FLAGS="${MACOS_CXX_FLAGS}" \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DFETCHCONTENT_SOURCE_DIR_EIGEN=${prefix}/include/eigen3 \
    -DFETCHCONTENT_SOURCE_DIR_NLOHMANN_JSON=${WORKSPACE}/srcdir/nlohmann_json/json \
    -DFETCHCONTENT_SOURCE_DIR_ABSEIL-CPP=${WORKSPACE}/srcdir/abseil-cpp/abseil-cpp \
    -DFETCHCONTENT_SOURCE_DIR_ABSCAB-CPP=${WORKSPACE}/srcdir/abscab-cpp/abscab-cpp \
    -DFETCHCONTENT_SOURCE_DIR_INDATA2JSON=${WORKSPACE}/srcdir/indata2json/indata2json \
    -DFETCHCONTENT_FULLY_DISCONNECTED=ON \
    -Dabsl_DIR=${prefix}/lib/cmake/absl \
    -DBLA_VENDOR=OpenBLAS \
    -DLAPACK_LIBRARIES="${libdir}/libopenblas.${dlext}" \
    -DBLAS_LIBRARIES="${libdir}/libopenblas.${dlext}"

# Build only the core library (not Python bindings or standalone)
make -j${nproc} vmecpp_core
cd ..

# ============================================
# Step 3: Build Julia wrapper (shared library)
# ============================================
echo "Building Julia wrapper..."
# Note: DirectorySource("./bundled") copies contents to srcdir root, not to srcdir/bundled/
# So the CMakeLists.txt and vmecpp_julia.cpp are at ${WORKSPACE}/srcdir/
mkdir -p julia-build && cd julia-build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=20 \
    -DCMAKE_CXX_FLAGS="${MACOS_CXX_FLAGS}" \
    -DJulia_PREFIX=${prefix} \
    -DVMECPP_SOURCE_DIR=${WORKSPACE}/srcdir/vmecpp \
    -DVMECPP_BUILD_DIR=${WORKSPACE}/srcdir/vmecpp-build \
    -DEIGEN_DIR=${prefix}/include/eigen3 \
    -Dabsl_DIR=${prefix}/lib/cmake/absl
make -j${nproc}
make install

# Install license
install_license ${WORKSPACE}/srcdir/vmecpp/LICENSE.txt
"""

# Augment sources and script for macOS SDK 12.3 (C++20 support)
# SDK 12.3 provides std::construct_at, std::filesystem, etc.
# Deployment target 10.15 for Fortran compiler compatibility (gfortran's clang-8 doesn't understand 11.x+)
sources, script = require_macos_sdk("12.3", sources, script; deployment_target="10.15")

# Platforms - use libjulia_platforms from common.jl (already included above)
platforms = reduce(vcat, libjulia_platforms.(julia_versions))

# Filter out unsupported platforms
filter!(p -> arch(p) != "armv7l", platforms)  # ARM32 often problematic
filter!(p -> arch(p) != "armv6l", platforms)  # Experimental
filter!(p -> !Sys.iswindows(p), platforms)    # Windows not supported yet
filter!(p -> !Sys.isfreebsd(p), platforms)    # FreeBSD not tested
# macOS enabled: using MacOSX12.3.sdk for proper C++20 support
filter!(p -> arch(p) != "i686", platforms)    # i686: 32-bit not needed
filter!(p -> arch(p) != "powerpc64le", platforms)  # ppc64le: not a target platform

# Expand C++ string ABIs
platforms = expand_cxxstring_abis(platforms)

# Products
products = [
    # RTLD_GLOBAL is required for CxxWrap-based Julia bindings to properly expose
    # C++ symbols across shared library boundaries (same as libcxxwrap_julia_jll)
    # dont_dlopen=true because the library depends on libjulia which can't be loaded
    # during BinaryBuilder's audit phase when cross-compiling
    LibraryProduct("libvmecpp_julia", :libvmecpp_julia; dlopen_flags=[:RTLD_GLOBAL], dont_dlopen=true),
]

# Dependencies
dependencies = [
    # Build dependencies
    BuildDependency(PackageSpec(;name="libjulia_jll", version="1.11.0")),
    BuildDependency("Eigen_jll"),

    # Runtime dependencies
    Dependency("libcxxwrap_julia_jll"; compat="~0.14.7"),
    Dependency("HDF5_jll"; compat="~1.14.6"),
    Dependency("NetCDF_jll"),
    Dependency("OpenBLAS_jll"),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isbsd, platforms)),
    Dependency("LLVMOpenMP_jll"; platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version = v"10",  # C++20 support
               julia_compat)
