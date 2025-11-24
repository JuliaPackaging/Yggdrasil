# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CImGuiPack"
version = v"0.10.0"

# Collection of sources required to build CImGuiPack
sources = [
    GitSource("https://github.com/JuliaImGui/cimgui-pack.git",
              "e5ac55e7d02d3a52292c8197de5a049037d5e234")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cimgui-pack
git submodule update --init --recursive --depth 1

mkdir build && cd build
export VERBOSE=1
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
         -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
         -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
install_license ../cimgui/LICENSE \
                ../cimgui/imgui/LICENSE.txt \
                ../cimplot/LICENSE \
                ../cimplot/implot/LICENSE \
                ../cimnodes/imnodes/LICENSE.md \
                ../cimgui_test_engine/LICENSE

# Copy generator files for cimgui
install -Dvm 644 ../cimgui_comments_output/*.json -t ${prefix}/share/cimgui

# And cimplot
install -Dvm 644 ../cimplot/generator/output/*.json -t ${prefix}/share/cimplot

# And cimnodes
install -Dvm 644 ../cimnodes/generator/output/*.json -t ${prefix}/share/cimnodes

# And cimgui_test_engine
install -Dvm 644 ../cimgui_test_engine/*.json -t ${prefix}/share/cimgui_test_engine
"""

# We don't build for armv6l because GLFW_jll doesn't support it, and we don't
# build for aarch64-freebsd or riscv64 because they're dependency pain.
platforms = filter(p -> arch(p) ∉ ("armv6l", "riscv64") && !(arch(p) == "aarch64" && os(p) == "freebsd"), supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libcimgui", :libcimgui),
    FileProduct("share/compile_commands.json", :compile_commands),

    FileProduct("share/cimgui/definitions.json", :cimgui_definitions),
    FileProduct("share/cimgui/impl_definitions.json", :cimgui_impl_definitions),
    FileProduct("share/cimgui/structs_and_enums.json", :cimgui_structs_and_enums),
    FileProduct("share/cimgui/typedefs_dict.json", :cimgui_typedefs_dict),

    FileProduct("share/cimplot/definitions.json", :cimplot_definitions),
    FileProduct("share/cimplot/structs_and_enums.json", :cimplot_structs_and_enums),
    FileProduct("share/cimplot/typedefs_dict.json", :cimplot_typedefs_dict),

    FileProduct("share/cimnodes/definitions.json", :cimnodes_definitions),
    FileProduct("share/cimnodes/structs_and_enums.json", :cimnodes_structs_and_enums),
    FileProduct("share/cimnodes/typedefs_dict.json", :cimnodes_typedefs_dict),

    FileProduct("share/cimgui_test_engine/definitions.json", :cimgui_test_engine_definitions),
    FileProduct("share/cimgui_test_engine/structs_and_enums.json", :cimgui_test_engine_structs_and_enums),
]

# Dependencies that must be installed before this package can be built
dependencies = [Dependency("GLFW_jll")]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.9", preferred_gcc_version=v"5")
