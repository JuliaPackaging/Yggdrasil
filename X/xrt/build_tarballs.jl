# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder
using Pkg

name = "xrt"
version = v"2.23.0"

# Collection of sources required to complete build
#
# Bumped from 2.17 to the XRT the AMD XDNA (RyzenAI NPU) stack pins --
# 202610.2.23.0, the commit the xdna-driver submodule tracks. This is the XRT
# whose xclbinutil packages the AIE_PARTITION/PDI sections mlir-aie's aiecc emits
# for AIE2p (npu2), and whose runtime (libxrt_coreutil) a Python-free host drives.
sources = [
    GitSource("https://github.com/Xilinx/XRT.git", "94e29e87fc90ea4037452f0dffa301cd700111ee"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
#
# fix-install-dir.patch is gone on 2.23: upstream now sets XRT_INSTALL_DIR to "."
# in src/CMake/xrtVariables.cmake, so nothing installs under a "xrt/" subdir.
#
# Several Windows mingw patches were upstreamed by XRT PR #8387 ("Improve
# compatibility with other Compilers like MinGW") and follow-ups -- unistd.h
# already lowercases <shlobj.h>, xclbinutil/xbutil link the mingw winsock libs
# themselves, config_reader uses __linux__ -- so those are dropped (left unused in
# ./bundled). The BinaryBuilder-specific ones are re-ported to 2.23:
# no_static_boost (the mingw boost_jll is shared-only) and disable_trace (mingw
# has no TraceLoggingProvider.h), plus aligned_malloc which still applies as-is.
script = raw"""
cd ${WORKSPACE}/srcdir/XRT
install_license LICENSE

# aiebu (a submodule) requires CMake >= 3.24 on Windows, newer than the image's
# 3.21. Drop the old system cmake so the HostBuildDependency CMake_jll below wins.
apk del cmake

# 2.23 pulls xdp, aiebu, aie-rt, gsl, elf (and more) in as submodules that
# GitSource does not fetch, so CMake configure fails on the missing CMakeLists in
# runtime_src/xdp and core/common/aiebu. Fetch them recursively -- the same thing
# the mlir_aie recipe does for its own submodules. The recorded commits are used,
# so the build stays reproducible.
git submodule update --init --recursive

if [[ "${target}" == *-linux-* ]]; then
    # Missing define for a large shift in the PCIe shim.
    atomic_patch -p1 ../patches/linux/huge_shift.patch
fi

if [[ "${target}" == *-w64-* ]]; then
    atomic_patch -p1 ../patches/windows/aligned_malloc.patch
    # BB's mingw boost_jll ships only shared libs, so use them (Boost_USE_STATIC_LIBS OFF).
    atomic_patch -p1 ../patches/windows/no_static_boost.patch
    # mingw has no <TraceLoggingProvider.h> (Windows ETW); stub the API out.
    atomic_patch -p1 ../patches/windows/disable_trace.patch
    # XRT's ssize_t/pid_t typedefs clash with mingw's; upstream's __GNU__ guard is
    # a typo (mingw is __GNUC__), so fix the guard.
    atomic_patch -p1 ../patches/windows/remove_duplicate_type_defs.patch
    export ADDITIONAL_CMAKE_CXX_FLAGS="-fpermissive -D_WINDOWS"
fi

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

# x86_64 Linux only: that is the RyzenAI NPU host. Windows is deferred -- its
# mingw patches are re-ported and applied in the script above and ready to go, but
# the mingw build still hits XRT's MSVC-isms (dllimport on inline definitions
# across many XRT_API_EXPORT headers) that need a Windows CI loop to sort out. Add
# a Windows platform here to pick that back up.
platforms = [Platform("x86_64", "linux"; libc = "glibc")]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built.
# xbutil was dropped: 2.23 no longer builds it (replaced by xrt-smi upstream).
products = [
    LibraryProduct("libxrt_coreutil", :libxrt_coreutil),
    LibraryProduct("libxilinxopencl", :libxilinxopencl),
    LibraryProduct("libxrt_core", :libxrt_core),
    LibraryProduct("libxdp_core", :libxdp_core),
    LibraryProduct("libxrt++", :libxrtxx),
    ExecutableProduct(["xclbinutil", "unwrapped/xclbinutil.exe"], :xclbinutil),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="boost_jll", version="1.79.0")),
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
    HostBuildDependency("CMake_jll"), # aiebu needs CMake >= 3.24 on Windows
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version=v"9")
