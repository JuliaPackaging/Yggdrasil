# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder

name = "xrt"
version = v"2.17"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Xilinx/XRT.git", "a75e9843c875bac0f52d34a1763e39e16fb3c9a7"),
    GitSource("https://github.com/Tencent/rapidjson.git", "ab1842a2dae061284c0a62dca1cc6d5e7e37e346"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
# Install rapidjson
cd ${WORKSPACE}/srcdir/rapidjson
cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX=${WORKSPACE}/srcdir/rapidjson/install \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DRAPIDJSON_BUILD_DOC=No \
    -DRAPIDJSON_BUILD_EXAMPLES=No \
    -DRAPIDJSON_BUILD_TESTS=No \
    -DRAPIDJSON_BUILD_CXX17=Yes
cmake --build build --parallel ${nproc}
cmake --install build

cd ${WORKSPACE}/srcdir/XRT
install_license LICENSE

# Apply patch with missing define
atomic_patch -p1 ../patches/linux/huge_shift.patch
# Explicitly add RapidJSON include paths
atomic_patch -p1 ../patches/fix_xclbinutil_cmake.patch

# mingw patches
atomic_patch -p1 ../patches/windows/remove_duplicate_type_defs.patch
atomic_patch -p1 ../patches/windows/disable_trace.patch
atomic_patch -p1 ../patches/windows/config_reader.patch
atomic_patch -p1 ../patches/windows/unistd.patch

atomic_patch -p1 ../patches/windows/no_static_boost.patch


if [[ "${target}" == *-w64-* ]]; then
    export ADDITIONAL_CMAKE_CXX_FLAGS="-fpermissive -D_WINDOWS"
fi

# Statically link to boost
export XRT_BOOST_INSTALL=${WORKSPACE}/destdir

cd src
cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${WORKSPACE}/srcdir/rapidjson/install \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_CXX_FLAGS="${ADDITIONAL_CMAKE_CXX_FLAGS}" \
    -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build

# Copy folder from xrt to folder to root dest folder
cd ${WORKSPACE}/destdir/
cp -r ./xrt/* ./
rm -rf xrt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
filter!(p -> arch(p) == "x86_64", platforms)
filter!(p -> Sys.iswindows(p) || (Sys.islinux(p) && libc(p) == "glibc"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libxrt_coreutil", :libxrt_coreutil),
    LibraryProduct("libxilinxopencl", :libxilinxopencl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("boost_jll"),
    BuildDependency("ELFIO_jll"),
    BuildDependency("OpenCL_Headers_jll"),
    Dependency("Libffi_jll"),
    Dependency("LibCURL_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("libdrm_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("Libuuid_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("LibYAML_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("Ncurses_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("ocl_icd_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("OpenSSL_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("protobuf_c_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("systemd_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("systemtap_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("OpenCL_jll", platforms=filter(Sys.iswindows, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version=v"9")