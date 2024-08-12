using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942 
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

name = "algoimWrapper"
version = v"0.2.1"
julia_versions = [v"1.6.3", v"1.7", v"1.8", v"1.9", v"1.10"]

sources = [
    GitSource("https://github.com/ericneiva/algoimWrapper.git", "d763149d1d2fdd698c4982c28cdeff69c9c16a07"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/algoimWrapper
mkdir build
cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DJulia_PREFIX=${prefix} \
    -DBLAS_LIBRARIES="${libdir}/libopenblas.${dlext}" \
    ..
VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}
"""

include("../../L/libjulia/common.jl")
platforms = expand_cxxstring_abis(vcat(libjulia_platforms.(julia_versions)...))

products = [
    LibraryProduct("libalgoimwrapper", :libalgoimwrapper),
]

dependencies = [
    BuildDependency("algoim_jll"),
    BuildDependency("libjulia_jll"),
    Dependency("libcxxwrap_julia_jll"),
    Dependency("OpenBLAS32_jll"), # links to LAPACKE
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"8", julia_compat="1.6")
