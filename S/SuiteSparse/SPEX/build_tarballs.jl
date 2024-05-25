include("../common.jl")

name = "SPEX"
version = v"3.1.0"
SS_version_str = "7.7.0"
SS_version = VersionNumber(SS_version_str)

sources = suitesparse_sources(SS_version)

# Bash recipe for building across all platforms
script = raw"""
PROJECTS_TO_BUILD="spex"
CMAKE_OPTIONS+=(
        -DSUITESPARSE_USE_SYSTEM_SUITESPARSE_CONFIG=ON
        -DSUITESPARSE_USE_SYSTEM_AMD=ON
        -DSUITESPARSE_USE_SYSTEM_COLAMD=ON
        -DSUITESPARSE_USE_SYSTEM_CAMD=ON
        -DSUITESPARSE_USE_SYSTEM_CCOLAMD=ON
        -DSUITESPARSE_USE_SYSTEM_UMFPACK=ON
        -DSUITESPARSE_USE_SYSTEM_CHOLMOD=ON
    )
""" * build_script(true) * raw"""
rm -f ${libdir}/libspexpython.*
rm -f ${includedir}/suitesparse/spex_python_connect.h
""" # remove python libs until a CMake variable is added.

# Add dependency on SuiteSparse_jll
dependencies = append!(dependencies, [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
    Dependency("GMP_jll"; compat="6.2.1"),
    Dependency("MPFR_jll"; compat="4.1.1"),
    Dependency("SuiteSparse_jll"; compat = "=$SS_version_str")
])
products = [
    LibraryProduct("libspex", :libspex),
]
build_tarballs(ARGS, name, version, sources, script, platforms, products, 
               dependencies; julia_compat="1.11",preferred_gcc_version=v"9")
