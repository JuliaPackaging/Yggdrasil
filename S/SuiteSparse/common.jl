using BinaryBuilder, Pkg


# Collection of sources required to build SuiteSparse
function suitesparse_sources(version::VersionNumber; kwargs...)
    suitesparse_version_sources = Dict(
        v"5.10.1" => [
            GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
                      "538273cfd53720a10e34a3d80d3779b607e1ac26")
        ],
        v"7.0.1" => [
            GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
                      "03350b0faef6b77d965ddb7c3cd3614a45376bfd"),
        ],
        v"7.2.0" => [
            GitSource("https://github.com/Wimmerer/SuiteSparse.git",
                "1b4edf467637dbf33a26eee9a6c20afa40c7c5ea")
        ]
    )
    return Any[
        suitesparse_version_sources[version]...,
    ]
end

# We enable experimental platforms as this is a core Julia dependency
platforms = supported_platforms(;experimental=true)
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

# The products that we will ensure are always built
products = [
    LibraryProduct("libsuitesparseconfig",   :libsuitesparseconfig),
    LibraryProduct("libamd",                 :libamd),
    LibraryProduct("libbtf",                 :libbtf),
    LibraryProduct("libcamd",                :libcamd),
    LibraryProduct("libccolamd",             :libccolamd),
    LibraryProduct("libcolamd",              :libcolamd),
    LibraryProduct("libcholmod",             :libcholmod),
    LibraryProduct("libldl",                 :libldl),
    LibraryProduct("libklu",                 :libklu),
    LibraryProduct("libumfpack",             :libumfpack),
    LibraryProduct("librbio",                :librbio),
    LibraryProduct("libspqr",                :libspqr),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libblastrampoline_jll"; compat="5.4.0"),
    BuildDependency("LLVMCompilerRT_jll",platforms=[Platform("x86_64", "linux"; sanitize="memory")]),
    HostBuildDependency(PackageSpec(; name="CMake_jll", version = v"3.24.3"))
]
