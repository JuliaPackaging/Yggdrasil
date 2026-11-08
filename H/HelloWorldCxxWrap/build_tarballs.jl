using BinaryBuilder, Pkg

include("../../L/libjulia/common.jl")

name = "HelloWorldCxxWrap"
version = v"1.0.0"

sources = [
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir
cmake -B build \
    -DJulia_PREFIX=${prefix} \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
install_license /usr/share/licenses/MIT
"""

platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libhello_cxxwrap", :libhello_cxxwrap),
]

dependencies = [
    BuildDependency(PackageSpec(; name="libjulia_jll", version="1.11.4")),
    Dependency("libcxxwrap_julia_jll"; compat="0.14.12"),
]

# libcxxwrap_julia_jll is built with GCC 10
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat=libjulia_julia_compat(julia_versions),
    preferred_gcc_version=v"10")
