using BinaryBuilder

# needed for libjulia_platforms and julia_versions
include("../../L/libjulia/common.jl")

name = "algoimWrapper"
version = v"0.3.2"

sources = [
    GitSource("https://github.com/ericneiva/algoimWrapper.git", "d12130919bc85a353d7eb6d9c583dff665e4f627"),
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

platforms = vcat(libjulia_platforms.(julia_versions)...)
# FreeBSD on 64bit ARM 64 is not supported by algoimWrapper
platforms = filter(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libalgoimwrapper", :libalgoimwrapper),
]

dependencies = [
    BuildDependency("algoim_jll"),
    BuildDependency("libjulia_jll"),
    Dependency("libcxxwrap_julia_jll"; compat="0.14.9"),
    Dependency("OpenBLAS32_jll"), # links to LAPACKE
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"8", julia_compat=libjulia_julia_compat(julia_versions))
