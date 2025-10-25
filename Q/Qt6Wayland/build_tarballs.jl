# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Qt6Wayland"
version = v"6.8.2"

# Set this to true first when updating the version. It will build only for the host (linux musl).
# After that JLL is in the registry, set this to false to build for the other platforms, using
# this same package as host build dependency.
const host_build = false

# Collection of sources required to build qt6
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$version/submodules/qtwayland-everywhere-src-$version.tar.xz",
                  "5e46157908295f2bf924462d8c0855b0508ba338ced9e810891fefa295dc9647"),
]

script = raw"""
cd $WORKSPACE/srcdir

mkdir build
cd build/
qtsrcdir=`ls -d ../qtwayland-*`

case "$bb_full_target" in

    x86_64-linux-musl-libgfortran5-cxx11)
        cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_FIND_ROOT_PATH=$prefix -DCMAKE_BUILD_TYPE=Release $qtsrcdir
    ;;

    *)
        cmake -DQT_HOST_PATH=$host_prefix -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_FIND_ROOT_PATH=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release $qtsrcdir
        # Fix needed for aarch64:
        sed -i 's!/workspace/destdir/bin/wayland-scanner!/workspace/x86_64-linux-musl-cxx11/destdir/bin/wayland-scanner!' CMakeCache.txt
    ;;

esac

cmake --build . --parallel ${nproc}
cmake --install .
install_license $WORKSPACE/srcdir/qt*-src-*/LICENSES/LGPL-3.0-only.txt
"""

# Get the common Qt platforms
include("../Qt6Base/common.jl")

# No Wayland on Windows and macOS
empty!(platforms_macos)
empty!(platforms_win)

# It seems Qt 6.8 Wayland doesn't compile out of the box on freeBSD and when forced requires
# proper support in Qt6Base. To be investigated on version upgrade.
filter!(!Sys.isfreebsd, platforms)

# The products that we will ensure are always built
products = [
    FileProduct("plugins", :qt6plugins_dir),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Qt6Base_jll"),
    Dependency("Qt6Base_jll"; compat="="*string(version)),
    HostBuildDependency("Qt6Declarative_jll"),
    Dependency("Qt6Declarative_jll"; compat="="*string(version)),
    BuildDependency("Xorg_xproto_jll"),
    BuildDependency("Vulkan_Headers_jll"),
]

if !host_build
    push!(dependencies, HostBuildDependency("Qt6Wayland_jll"))
end

init_block = raw"""
ENV["QT_PLUGIN_PATH"] = qt6plugins_dir
ENV["__EGL_VENDOR_LIBRARY_DIRS"] = get(ENV, "__EGL_VENDOR_LIBRARY_DIRS", "/usr/share/glvnd/egl_vendor.d")
"""

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"10", preferred_llvm_version=qt_llvm_version, julia_compat="1.6", init_block)
