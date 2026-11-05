using BinaryBuilder, Pkg

name = "VTK_julia"
version = v"0.1.0"

sources = [
    GitSource(
        "https://github.com/ffrancesco94/VTK_cxxwrap.git",
        "c4e77590ee854480821233058304bf30fbfb5f21";
        tag="v$(version)+vtk9.7",
    ),
]

script = raw"""
cd ${WORKSPACE}/srcdir/VTK_cxxwrap

cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DJulia_PREFIX=${prefix}

cmake --build build --parallel ${nproc}
cmake --install build
install_license LICENSE
"""

include("../../L/libjulia/common.jl")
filter!(>=(v"1.11"), julia_versions)
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# VTK_jll is built only for 64-bit targets.
filter!(p -> nbits(p) == 64, platforms)

# VTK_jll has no Windows build.
filter!(!Sys.iswindows, platforms)

products = [
    # VTK.jl preloads MPI and VTK component libraries before loading the wrapper.
    LibraryProduct("libvtk_julia", :libvtk_julia; dont_dlopen=true),
    FileProduct("VTKGen.jl", :VTKGen_exports),
]

dependencies = [
    BuildDependency("libjulia_jll"),
    Dependency("libcxxwrap_julia_jll"; compat="0.14.12"),
    # No MPI augmentation: the wrapper uses no MPI API; VTK_jll owns MPI selection.
    Dependency("VTK_jll"; compat="9.7.1"),
]

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"10",
    julia_compat=libjulia_julia_compat(julia_versions),
)
