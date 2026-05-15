# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CImPlot3D"
version = v"0.4.0" # tracking implot3d release tags

# Sources required to build CImPlot3D
sources = [
    # cimplot3d ships the C wrapper; implot3d is its git submodule pinned at a
    # SHA that matches the wrapper's generated bindings (currently v0.4 of
    # implot3d). A recursive submodule init in the script keeps them locked.
    GitSource("https://github.com/cimgui/cimplot3d.git",
              "8c1c16e98fdddc4b3ee78bf0f89e0dd708be79e0"),

    # Bundled CMakeLists.txt that links against CImGuiPack_jll's exported
    # cimgui::cimgui target rather than rebuilding imgui sources locally —
    # this is what keeps ImGuiContext / ImPlot3DContext globals shared with
    # the libcimgui.dylib that CImGui.jl loads at runtime.
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms.
# DirectorySource("./bundled") copies bundled/CMakeLists.txt to
# $WORKSPACE/srcdir/CMakeLists.txt; that CMakeLists references
# cimplot3d/* paths relative to itself, which line up with where the
# GitSource clones cimplot3d.
script = raw"""
cd $WORKSPACE/srcdir
git -C cimplot3d submodule update --init --recursive --depth 1

mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
         -DCMAKE_PREFIX_PATH=${prefix} \
         -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
         -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install

install_license $WORKSPACE/srcdir/cimplot3d/implot3d/LICENSE
"""

# Match CImGuiPack's platform filter (excludes armv6l, riscv64,
# aarch64-freebsd because of GLFW_jll / dependency limitations).
platforms = filter(p -> arch(p) ∉ ("armv6l", "riscv64") &&
                        !(arch(p) == "aarch64" && os(p) == "freebsd"),
                   supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libcimplot3d", :libcimplot3d),
]

# Dependencies that must be installed before this package can be built.
# We pin against the published CImGuiPack_jll v0.8.x line because the
# unreleased Yggdrasil HEAD (v0.11.x) drops the libcxxwrap_julia_jll
# dependency, which would change which ImGui symbols are reachable.
dependencies = [
    Dependency("CImGuiPack_jll"; compat="0.8"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.9", preferred_gcc_version=v"5")
