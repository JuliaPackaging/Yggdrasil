# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder
using Pkg

name = "xrt"
version = v"2.17"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Xilinx/XRT.git", "a75e9843c875bac0f52d34a1763e39e16fb3c9a7"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/XRT
install_license LICENSE

if [[ "${target}" == *-linux-* ]]; then
    # Apply patch with missing define
    atomic_patch -p1 ../patches/linux/huge_shift.patch
fi

if [[ "${target}" == *-w64-* ]]; then
    # mingw patches
    atomic_patch -p1 ../patches/windows/fix_xclbinutil_cmake.patch
    atomic_patch -p1 ../patches/windows/remove_duplicate_type_defs.patch
    atomic_patch -p1 ../patches/windows/disable_trace.patch
    atomic_patch -p1 ../patches/windows/config_reader.patch
    atomic_patch -p1 ../patches/windows/unistd.patch
    atomic_patch -p1 ../patches/windows/ocl_bindings.patch
    atomic_patch -p1 ../patches/windows/aligned_malloc.patch
    atomic_patch -p1 ../patches/windows/no_static_boost.patch
    atomic_patch -p1 ../patches/windows/config.patch
    atomic_patch -p1 ../patches/windows/xbutil.patch
    atomic_patch -p1 ../patches/windows/xdp-exports.patch
    atomic_patch -p1 ../patches/windows/xrt-core-lib.patch 
    export ADDITIONAL_CMAKE_CXX_FLAGS="-fpermissive -D_WINDOWS"
fi

atomic_patch -p1 ../patches/fix-install-dir.patch

# Statically link to boost
export XRT_BOOST_INSTALL=${WORKSPACE}/destdir

cd src
cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_CXX_FLAGS="${ADDITIONAL_CMAKE_CXX_FLAGS}" \
    -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
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
    LibraryProduct("libxrt_core", :libxrt_core),
    LibraryProduct("libxdp_core", :libxdp_core),
    LibraryProduct("libxrt++", :libxrtxx),
    ExecutableProduct(["xbutil", "unwrapped/xbutil.exe"], :xbutil),
    ExecutableProduct(["xclbinutil", "unwrapped/xclbinutil.exe"], :xclbinutil),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="boost_jll", version=v"1.79.0")),
    BuildDependency("ELFIO_jll"),
    BuildDependency("OpenCL_Headers_jll"),
    Dependency("ocl_icd_jll"),
    Dependency("rapidjson_jll"),
    Dependency("LibCURL_jll", platforms=filter(Sys.islinux, platforms); compat="7.73, 8"),
    Dependency("libdrm_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("Libuuid_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("LibYAML_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("Ncurses_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("OpenSSL_jll", platforms=filter(Sys.islinux, platforms); compat="3.0.8"),
    Dependency("protobuf_c_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("systemd_jll", platforms=filter(Sys.islinux, platforms)),
    Dependency("systemtap_jll", platforms=filter(Sys.islinux, platforms)),
]

init_block = raw"""
ENV["XILINX_XRT"] = xrt_jll.artifact_dir
"""

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version=v"9", init_block)
