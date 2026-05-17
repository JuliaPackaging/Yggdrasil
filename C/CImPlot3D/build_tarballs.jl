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

    # cimplot3d's generator does `require"cpp2ffi"` and a `dofile` of cimgui's
    # generator output, expecting cimgui as a sibling directory. Pinned to the
    # commit that introduced GetScriptArgs (which cimplot3d 8c1c16e9 relies on).
    GitSource("https://github.com/cimgui/cimgui.git",
              "ad70f13873e0e9e7a8ba14aa8feebbcbff3b8098"),

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

# Regenerate cimplot3d.cpp/.h/.json with comments enabled so docstrings can
# be lifted into a future Julia wrapper. Mirrors the same pattern as
# cimgui-pack's build.jl for cimgui itself. The wrapper script passes `gcc`
# as the C preprocessor; we redirect to ${HOSTCC} so we use the host C
# compiler (the default `gcc` would be the cross-compiler, wrong arch for
# something that runs at build time).
cd cimplot3d/generator
sed -i 's|TARGETS="internal"|TARGETS="internal comments"|' generator.sh
sed -i "s|gcc \"\$TARGETS\"|${HOSTCC} \"\$TARGETS\"|" generator.sh
bash ./generator.sh
cd $WORKSPACE/srcdir

mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
         -DCMAKE_PREFIX_PATH=${prefix} \
         -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
         -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install

# Install the generator's JSON outputs so a future Julia wrapper can
# auto-generate bindings (mirrors CImGuiPack's pattern for cimplot etc).
install -Dvm 644 $WORKSPACE/srcdir/cimplot3d/generator/output/*.json -t ${prefix}/share/cimplot3d

install_license $WORKSPACE/srcdir/cimplot3d/implot3d/LICENSE
"""

# Match CImGuiPack's platform filter (excludes armv6l, riscv64,
# aarch64-freebsd because of GLFW_jll / dependency limitations).
# We additionally exclude Windows: CImGuiPack's libcimgui.dll only
# exports the cimgui C wrappers (`ig*`), not the underlying `ImGui::*`
# C++ symbols that cimplot3d.cpp calls directly, so the link fails.
# Revisit if cimgui-pack starts exporting all symbols on Windows.
platforms = filter(p -> arch(p) ∉ ("armv6l", "riscv64") &&
                        !(arch(p) == "aarch64" && os(p) == "freebsd") &&
                        os(p) != "windows",
                   supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libcimplot3d", :libcimplot3d),

    FileProduct("share/cimplot3d/definitions.json",       :cimplot3d_definitions),
    FileProduct("share/cimplot3d/structs_and_enums.json", :cimplot3d_structs_and_enums),
    FileProduct("share/cimplot3d/typedefs_dict.json",     :cimplot3d_typedefs_dict),
    FileProduct("share/cimplot3d/constants.json",         :cimplot3d_constants),
]

dependencies = [
    Dependency("CImGuiPack_jll"; compat="0.11"),
    HostBuildDependency("LuaJIT_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.9", preferred_gcc_version=v"5")
