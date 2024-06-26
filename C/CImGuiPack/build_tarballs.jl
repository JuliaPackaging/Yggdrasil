# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

include("../../L/libjulia/common.jl")

name = "CImGuiPack"
version = v"0.3.0"

# Collection of sources required to build CImGuiPack
sources = [
    GitSource("https://github.com/Gnimuc/CImGui.jl.git",
              "664b68d2f5d33581e6c2912e74956fcdf653ff86")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/CImGui.jl/cimgui-pack
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
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# We don't build for armv6l because GLFW_jll doesn't support it
platforms = filter(p -> arch(p) != "armv6l", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcimgui", :libcimgui),
    FileProduct("share/compile_commands.json", :compile_commands)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(;name="libjulia_jll", version=v"1.10.10")),
    Dependency("GLFW_jll"),
    Dependency("libcxxwrap_julia_jll"; compat="0.13")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")
