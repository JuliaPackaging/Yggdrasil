# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "Qt6Positioning"
version = v"6.8.2"

# Collection of sources required to build qt6
sources = [
    ArchiveSource("https://download.qt.io/official_releases/qt/$(version.major).$(version.minor)/$version/submodules/qtpositioning-everywhere-src-$version.tar.xz",
                  "df30664f4e936466a7e1157ff26abc61efb5e94c9eb8750e1bcdffeec95db8e5"),
]

script = raw"""
cd $WORKSPACE/srcdir

mkdir build
cd build/
qtsrcdir=`ls -d ../qtpositioning-*`

case "$bb_full_target" in

    *)
        cmake -G Ninja \
            -DQT_HOST_PATH=$host_prefix \
            -DPython_ROOT_DIR=/usr \
            -DCMAKE_INSTALL_PREFIX=${prefix} \
            -DCMAKE_PREFIX_PATH=$host_prefix \
            -DCMAKE_FIND_ROOT_PATH=$prefix \
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
            -DQT_NO_APPLE_SDK_AND_XCODE_CHECK=ON \
            -DCMAKE_BUILD_TYPE=Release \
            $qtsrcdir
    ;;

esac

cmake --build . --parallel ${nproc}
cmake --install .
install_license $WORKSPACE/srcdir/qt*-src-*/LICENSES/LGPL-3.0-only.txt
"""

sources, script = require_macos_sdk("14.0", sources, script; deployment_target="12")

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(filter(!Sys.isapple, supported_platforms()))
filter!(p -> arch(p) != "armv6l", platforms) # No OpenGL on armv6
platforms_macos = [ Platform("x86_64", "macos"), Platform("aarch64", "macos") ]

# The products that we will ensure are always built
products = [
    LibraryProduct(["Qt6Positioning", "libQt6Positioning", "QtPositioning"], :libqt6positioning),
    LibraryProduct(["Qt6PositioningQuick", "libQt6PositioningQuick", "QtPositioningQuick"], :libqt6positioningquick),
]

products_macos = [
    FrameworkProduct("QtPositioning", :libqt6positioning),
    FrameworkProduct("QtPositioningQuick", :libqt6positioningquick),
]

# We must use the same version of LLVM for the build toolchain and LLVMCompilerRT_jll
# LLVM is needed for __isPlatformVersionAtLeast on mac
llvm_version = v"16.0.6"

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=llvm_version)),
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=llvm_version);
                    platforms=filter(p -> Sys.isapple(p), platforms_macos)),
    HostBuildDependency("Qt6Base_jll"),
    HostBuildDependency("Qt6Declarative_jll"),
    Dependency("Qt6Base_jll"; compat="="*string(version)),
    Dependency("Qt6Declarative_jll"; compat="="*string(version)),
]

if any(should_build_platform.(triplet.(platforms_macos)))
    build_tarballs(ARGS, name, version, sources, script, platforms_macos, products_macos, dependencies; preferred_gcc_version = v"10", julia_compat="1.6")
end

if any(should_build_platform.(triplet.(platforms)))
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"10", julia_compat="1.6")
end
