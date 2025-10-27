include("../common.jl")

name = "CXSparse"

upstream_version = v"4.4.2"
version_offset = v"0.0.0" # reset to 0.0.0 once the upstream version changes
version = VersionNumber(upstream_version.major * 100 + version_offset.major,
                        upstream_version.minor * 100 + version_offset.minor,
                        upstream_version.patch * 100 + version_offset.patch)


SS_version_str = "7.11.0"
SS_version = VersionNumber(SS_version_str)
LLVM_version = v"16.0.6"
sources = suitesparse_sources(SS_version)

# Bash recipe for building across all platforms
script = raw"""
PROJECTS_TO_BUILD="cxsparse"
if [[ "${target}" == aarch64-apple-* ]]; then
    # Linking libomp requires the function `__divdc3`, which is implemented in
    # `libclang_rt.osx.a` from LLVM compiler-rt.
    CMAKE_OPTIONS+=(
        -DCMAKE_SHARED_LINKER_FLAGS="-L${libdir}/darwin -lclang_rt.osx"
    )
fi
""" * build_script(; use_omp=false)

# Add dependency on SuiteSparse_jll
dependencies = append!(dependencies, [
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll",
                                uuid="4e17d02c-6bf5-513e-be62-445f41c75a11",
                                version=LLVM_version);
                    platforms=[Platform("aarch64", "macos")]),
    Dependency("CompilerSupportLibraries_jll"),
])

products = [
    LibraryProduct("libcxsparse", :libcxsparse),
    LibraryProduct("libsuitesparseconfig", :libsuitesparseconfig_cxsparse),
]
build_tarballs(ARGS, name, version, sources, script, platforms,
               products, dependencies; julia_compat="1.6",
               preferred_llvm_version=LLVM_version)
