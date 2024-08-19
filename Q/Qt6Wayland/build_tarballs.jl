# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Qt6Wayland"
version = v"6.7.1"

# Set this to true first when updating the version. It will build only for the host (linux musl).
# After that JLL is in the registyry, set this to false to build for the other platforms, using
# this same package as host build dependency.
const host_build = false

# Collection of sources required to build qt6
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$version/submodules/qtwayland-everywhere-src-$version.tar.xz",
                  "7ef176a8e701c90edd8e591dad36f83c30d623ef94439ff62cafcffd46a83d20"),
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

cmake --build . --parallel 1
cmake --install .
install_license $WORKSPACE/srcdir/qt*-src-*/LICENSES/LGPL-3.0-only.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
if host_build
    platforms = [Platform("x86_64", "linux",cxxstring_abi=:cxx11,libc="musl")]
else
    platforms = expand_cxxstring_abis(filter(p -> arch(p) != "armv6l" && Sys.islinux(p), supported_platforms()))
end

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

include("../../fancy_toys.jl")

init_block = raw"""
ENV["QT_PLUGIN_PATH"] = qt6plugins_dir
ENV["__EGL_VENDOR_LIBRARY_DIRS"] = get(ENV, "__EGL_VENDOR_LIBRARY_DIRS", "/usr/share/glvnd/egl_vendor.d")
"""

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"10", julia_compat="1.6", init_block)
