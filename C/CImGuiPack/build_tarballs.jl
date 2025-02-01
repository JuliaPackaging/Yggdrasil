# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

include("../../L/libjulia/common.jl")

name = "CImGuiPack"
version = v"0.7.1"

# Collection of sources required to build CImGuiPack
sources = [
    GitSource("https://github.com/JuliaImGui/cimgui-pack.git",
              "cb6b62c98883bff410faff7464d11af77ab967da")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cimgui-pack
git submodule update --init --recursive --depth 1
cp test_engine/overrides.h test_engine/src/overrides.h

mkdir build && cd build
export VERBOSE=1
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
         -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
         -DJulia_PREFIX=${prefix} \
         -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
install_license ../cimgui/LICENSE ../cimgui/imgui/LICENSE.txt ../cimplot/LICENSE ../cimplot/implot/LICENSE ../cimnodes/imnodes/LICENSE.md

# Copy generator files for cimgui
install -Dvm 644 ../cimgui_comments_output/*.json -t ${prefix}/share/cimgui

# And cimplot
install -Dvm 644 ../cimplot/generator/output/*.json -t ${prefix}/share/cimplot

# And cimnodes
install -Dvm 644 ../cimnodes/generator/output/*.json -t ${prefix}/share/cimnodes
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
cimgui_julia_versions = filter(>=(v"1.9"), julia_versions)
platforms = vcat(libjulia_platforms.(cimgui_julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# We don't build for armv6l because GLFW_jll doesn't support it, and we don't
# build for aarch64-freebsd or riscv64 because they're dependency pain.
platforms = filter(p -> arch(p) != "armv6l" && arch(p) != "riscv64" && !(arch(p) == "aarch64" && os(p) == "freebsd"), platforms)

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
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(;name="libjulia_jll", version=v"1.10.13")),
    Dependency("GLFW_jll"),
    Dependency("libcxxwrap_julia_jll"; compat="0.13.3")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.9", preferred_gcc_version=v"8")
