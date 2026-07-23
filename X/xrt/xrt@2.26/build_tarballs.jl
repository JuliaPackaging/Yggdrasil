# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder
using Pkg

name = "xrt"
version = v"2.26.0"

# Collection of sources required to complete build
#
# Bumped from 2.17 to the XRT the AMD XDNA (RyzenAI NPU) stack pins --
# 202610.2.23.0, the commit the xdna-driver submodule tracks. This is the XRT
# whose xclbinutil packages the AIE_PARTITION/PDI sections mlir-aie's aiecc emits
# for AIE2p (npu2), and whose runtime (libxrt_coreutil) a Python-free host drives.
sources = [
    GitSource("https://github.com/Xilinx/XRT.git", "b4bbf24c54b355b585d59f15264aba47d9aa54b9"),
    GitSource("https://github.com/amd/xdna-driver.git", "0697b1720fc539f57bdc8d5854ddf7c7014ae160"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/XRT
install_license LICENSE

# aiebu (a submodule) requires CMake >= 3.24 on Windows, newer than the image's
# 3.21. Drop the old system cmake so the HostBuildDependency CMake_jll below wins.
apk del cmake

# Fetch submodules for XRT
git submodule update --init --recursive

if [[ "${target}" == *-linux-* ]]; then
    # Missing define for a large shift in the PCIe shim.
    atomic_patch -p1 ../patches/linux/huge_shift.patch
fi

# Quiet by default
atomic_patch -p1 ../patches/quiet-verbosity.patch

# xrt::device::get_info's kdma case returns a bare 0 (an int) from its exception fallback,
# but the query result type is uint32_t, so on a device where kds_numcdmas is unsupported
# -- an NPU -- the std::any holds an int while any_cast expects uint32_t, and every kdma
# query throws "bad any_cast". Return uint32_t so the fallback matches the declared type.
atomic_patch -p1 ../patches/kdma_any_cast.patch

if [[ "${target}" == *-w64-* ]]; then
    atomic_patch -p1 ../patches/windows/aligned_malloc.patch
    atomic_patch -p1 ../patches/windows/no_static_boost.patch
    atomic_patch -p1 ../patches/windows/disable_trace.patch
    atomic_patch -p1 ../patches/windows/remove_duplicate_type_defs.patch
    atomic_patch -p1 ../patches/windows/fix_aie-pdi-transform.patch
    atomic_patch -p1 ../patches/windows/fix_aiebu_cmake.patch
    atomic_patch -p1 ../patches/windows/fix_XRT_CORE_COMMON_EXPORT.patch
    atomic_patch -p1 ../patches/windows/fix_aiebu_metrics.patch
    atomic_patch -p1 ../patches/windows/export_all_symbols.patch
    atomic_patch -p1 ../patches/windows/no_dupenv.patch
    atomic_patch -p1 ../patches/windows/fix_smi_symbols_export.patch
    atomic_patch -p1 ../patches/windows/fix_OpenCL_dll_install.patch
    # without -DXRT_API_SOURCE, gcc complains about `error: function ‘xrt::elf::elf(std::shared_ptr<xrt::elf_impl>)’ definition is marked dllimport`
    # in XRT/src/runtime_src/core/include/xrt/experimental/xrt_elf.h:197:3
    export ADDITIONAL_CMAKE_CXX_FLAGS="-fpermissive -D_WINDOWS -DXRT_API_SOURCE"
fi

# Statically link to boost
export XRT_BOOST_INSTALL=${WORKSPACE}/destdir

# 1. BUILD XRT
cd src
cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_CXX_FLAGS="${ADDITIONAL_CMAKE_CXX_FLAGS}" \
    -DXRT_RC_VERSION=202610.2.23.0 \
    -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build

if [[ "${target}" == *-w64-* ]]; then
    cd ${prefix}
    mv *.dll ${libdir}/
    mv *.exe ${bindir}/
    mv unwrapped ${bindir}/
    mv setup.bat xball xbmgmt xbmgmt.bat xclbinutil xclbinutil.bat xrt-smi xrt-smi.bat ${bindir}/
fi

# 2. BUILD XDNA SHIM (Linux x86_64 only, where the NPU host lives)
if [[ "${target}" == *-linux-* ]]; then
    cd ${WORKSPACE}/srcdir/xdna-driver

    # the distro-detection check is fatal off a known distro; make it non-fatal.
    sed -i 's/message(FATAL_ERROR/message(STATUS/g' CMake/pkg.cmake

    # drop -Werror so upstream warnings don't fail the build.
    find . -type f -name "CMakeLists.txt" -exec sed -i 's/-Werror//g' {} \;

    # device.cpp uses pidfd syscalls with no fallback; define the x86_64 numbers.
    printf '#include <sys/syscall.h>\n#ifndef SYS_pidfd_open\n#define SYS_pidfd_open 434\n#endif\n#ifndef SYS_pidfd_getfd\n#define SYS_pidfd_getfd 438\n#endif\n' | cat - src/shim/device.cpp > device.tmp
    mv device.tmp src/shim/device.cpp

    # host/platform_host.cpp includes <drm/drm.h>, but the shim never puts libdrm
    # on its include path. Prepend it (CMAKE_CXX_FLAGS gets overwritten downstream).
    printf 'include_directories("%s/include/libdrm" "%s/include")\n' "${prefix}" "${prefix}" | cat - src/shim/CMakeLists.txt > shim_cmake.tmp
    mv shim_cmake.tmp src/shim/CMakeLists.txt

    # drop the virtio-gpu (VM-guest) backend -- it needs VIRTGPU blob/context UAPI
    # libdrm lacks, and a native host never uses it (backends self-register, so the
    # virtgpu driver just goes unregistered).
    rm -f src/shim/virtio/*.cpp

    # link libdl (dladdr) and libpthread (pthread_create); the shim omits both,
    # and BB's split glibc + -Wl,-z,defs make the missing symbols fatal.
    echo 'find_package(Threads REQUIRED)' >> src/shim/CMakeLists.txt
    echo 'target_link_libraries(xrt_driver_xdna PRIVATE ${CMAKE_DL_LIBS} Threads::Threads)' >> src/shim/CMakeLists.txt

    # The shim builds XRT via add_subdirectory(xrt/src); point that at our patched tree.
    rm -rf xrt
    ln -s ${WORKSPACE}/srcdir/XRT xrt

    # SKIP_KMOD=1 builds only the userspace shim.
    cmake -S . -B build \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_CXX_STANDARD=17 \
        -DCMAKE_CXX_STANDARD_REQUIRED=ON \
        -DSKIP_KMOD=1 \
        -DCMAKE_BUILD_TYPE=Release

    cmake --build build --parallel ${nproc}

    # Co-locate the shim with libxrt_core so driver_plugin_paths() finds it.
    cp build/src/shim/libxrt_driver_xdna.so* ${prefix}/lib/
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc")
    Platform("x86_64", "windows")
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libxrt_coreutil", :libxrt_coreutil),
    LibraryProduct("libxilinxopencl", :libxilinxopencl),
    LibraryProduct("libxrt_core", :libxrt_core),
    LibraryProduct("libxdp_core", :libxdp_core),
    LibraryProduct("libxrt++", :libxrtxx),
    ExecutableProduct(["xclbinutil", "unwrapped/xclbinutil.exe"], :xclbinutil),
    ExecutableProduct(["xbmgmt", "unwrapped/xbmgmt.exe"], :xbmgmt),
    ExecutableProduct("unwrapped/xrt-capture", :xrt_capture),
    ExecutableProduct("unwrapped/xrt-replay", :xrt_replay),
    ExecutableProduct("unwrapped/xrt-runner", :xrt_runner),
    ExecutableProduct(["xrt-smi", "unwrapped/xrt-smi.exe"], :xrt_smi),
    # Only exists on Linux, but it's just a shim that's loaded dymically at runtime, so exclude it:
    # LibraryProduct("libxrt_driver_xdna", :libxrt_driver_xdna),
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
    julia_compat="1.6", preferred_gcc_version=v"10")
