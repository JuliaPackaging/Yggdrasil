include("../common.jl")

name = "CXSparse"
version = v"4.4.0"
SS_version_str = "7.7.0"
SS_version = VersionNumber(SS_version_str)
sources = suitesparse_sources(SS_version)

# Bash recipe for building across all platforms
script = raw"""
PROJECTS_TO_BUILD="cxsparse"
CMAKE_OPTIONS+=(
        -DSUITESPARSE_USE_SYSTEM_SUITESPARSE_CONFIG=ON
    )
if [[ "${target}" == aarch64-apple-* ]]; then
    # Linking libomp requires the function `__divdc3`, which is implemented in
    # `libclang_rt.osx.a` from LLVM compiler-rt.
    CMAKE_OPTIONS+=(
        -DCMAKE_SHARED_LINKER_FLAGS="-L${libdir}/darwin -lclang_rt.osx"
    )
fi
""" * build_script(; use_omp=true)

# Add dependency on SuiteSparse_jll
dependencies = append!(dependencies, [
    Dependency("SuiteSparse_jll"; compat = "=$SS_version_str"),
    Dependency("CompilerSupportLibraries_jll")
])

products = [
    LibraryProduct("libcxsparse", :libcxsparse)
]
build_tarballs(ARGS, name, version, sources, script, platforms,
               products, dependencies; julia_compat="1.10")
