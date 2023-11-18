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
        v"7.2.1" => [
            GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
                      "d6c84f7416eaee0d23d61c6c49ad1b73235d2ea2")
        ],
        v"7.3.0" => [
            GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
                      "fad1f30fa260975466bb0ad7da1aabf054517399")
        ]
    )
    return Any[
        suitesparse_version_sources[version]...,
    ]
end

# We enable experimental platforms as this is a core Julia dependency
platforms = supported_platforms()

# Disable sanitize build until it is fixed for the latest LLVM
#push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

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
    Dependency("libblastrampoline_jll"; compat="5.8.0"),
    BuildDependency("LLVMCompilerRT_jll",platforms=[Platform("x86_64", "linux"; sanitize="memory")]),
    HostBuildDependency(PackageSpec(; name="CMake_jll", version = v"3.24.3"))
]
