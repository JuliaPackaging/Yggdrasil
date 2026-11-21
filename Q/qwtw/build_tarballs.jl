# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "qwtw"
version = v"4.0.0"

sources = [
    GitSource("https://github.com/ig-or/qwtw.git",
              "b7f9d3c2379aff413c4de996e99b31ed0fe38760";
              tag="v$(version)"),
    # Upstream p12tic/qwt is an unmaintained mirror (last commit 2019, pre-Qt6), and
    # Yggdrasil's qwt_jll (v6.0.0) is built against Qt5. This fork is qwtw's extern/qwt
    # submodule carrying Qt 6.10 compatibility fixes across 48 files; it can be replaced
    # with Dependency("qwt_jll") once qwt_jll is updated to Qwt 6.3+ on Qt6Base_jll.
    GitSource("https://github.com/ig-or/qwt.git",
              "8a5ec6c5e507047c44860f3e3bdd8b0b1df9f922"),
]

script = raw"""
# Qt 6.10's CMake config requires CMake >= 3.22, while the rootfs image ships 3.21.7
apk del cmake

# Place Qwt in extern/qwt where qwtw's CMakeLists.txt expects its submodule
rm -rf ${WORKSPACE}/srcdir/qwtw/extern/qwt
mv -v ${WORKSPACE}/srcdir/qwt ${WORKSPACE}/srcdir/qwtw/extern/qwt

cd ${WORKSPACE}/srcdir/qwtw

# -DBUILD_TESTING=OFF: skip building/installing developer test binaries (qttest, qwtest2)
# -DNO_VERSION_INFO=ON: skip Python/git build-number generator scripts during tarball builds
# -DWITH_UDP_SYNC=ON: enable multicast UDP marker/clip synchronization for QWTWPlot.jl callbacks
# -DUSE_MGL=OFF: disable optional MathGL 3D plotting (MathGL_jll links Qt5, incompatible with Qt6)
cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DQT_HOST_PATH=${host_prefix} \
    -DBUILD_TESTING=OFF \
    -DNO_VERSION_INFO=ON \
    -DWITH_UDP_SYNC=ON \
    -DUSE_MGL=OFF

cmake --build build --parallel ${nproc}
cmake --install build

install_license ${WORKSPACE}/srcdir/qwtw/LICENSE ${WORKSPACE}/srcdir/qwtw/extern/qwt/COPYING
"""

# Qt6Base_jll 6.10 on macOS links UniformTypeIdentifiers.framework (introduced in macOS 11,
# built against MacOSX14.0.sdk with deployment target 12). BinaryBuilder's macOS system
# framework allowlist predates macOS 11, so audit logs a benign warning that
# UniformTypeIdentifiers.framework could not be auto-mapped; macOS 12+ resolves it from the OS.
sources, script = require_macos_sdk("14.0", sources, script; deployment_target="12")

# Match Qt6Base_jll's supported platforms (Q/Qt6Base/common.jl)
platforms = expand_cxxstring_abis(supported_platforms())
filter!(p -> !(arch(p) == "aarch64" && Sys.isfreebsd(p)), platforms) # No Qt6Base_jll (no OpenGL on aarch64 FreeBSD)
filter!(p -> arch(p) != "armv6l", platforms)                         # No Qt6Base_jll (no OpenGL on armv6l)
filter!(p -> arch(p) != "riscv64", platforms)                        # No Qt6Base_jll (no OpenGL on riscv64)

products = [
    LibraryProduct("libqwtw", :qwtw),
    ExecutableProduct("qwproc", :qwproc),
]

dependencies = [
    # Qt 6.10 requires CMake >= 3.22
    HostBuildDependency(PackageSpec(; name="CMake_jll", version="3.31.9")),
    HostBuildDependency("Qt6Base_jll"),
    Dependency("Qt6Base_jll"; compat="~6.10.2"),
    Dependency("Libglvnd_jll"; compat="1.7.0", platforms=filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)),
    # Julia 1.6 ships CompilerSupportLibraries_jll 0.3.6, 1.7-1.8 ship 0.5.x, and 1.9+ ship 1.x
    Dependency("CompilerSupportLibraries_jll"; compat="0.3.6 - 1", platforms=filter(!Sys.isbsd, platforms)),
    BuildDependency("Vulkan_Headers_jll"),
]

platforms_win = filter(Sys.iswindows, platforms)
platforms_other = setdiff(platforms, platforms_win)

# GCC <= 12 fails with an internal compiler error on Qt 6 headers when targeting mingw-w64
if any(should_build_platform.(triplet.(platforms_win)))
    build_tarballs(ARGS, name, version, sources, script, platforms_win, products, dependencies;
                   julia_compat="1.6", preferred_gcc_version=v"13")
end
# Qt 6.10 headers and std::filesystem require C++17 (GCC >= 10, matching Qt6Base_jll)
if any(should_build_platform.(triplet.(platforms_other)))
    build_tarballs(ARGS, name, version, sources, script, platforms_other, products, dependencies;
                   julia_compat="1.6", preferred_gcc_version=v"10")
end
