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
        ],
        v"7.4.0" => [
            GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
                      "df91d7be262e6b5cddf5dd23ff42dec1713e7947")
        ],
        v"7.5.0" => [
            GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
                      "da5050cd3f6b6a15ec4d7c42b2c1e2dfe4f8ef6e")
        ],
        v"7.5.1" => [
            GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
                      "71d6d42cb60b533bd001d3e5514e11120919c43a")
        ],
        v"7.6.0" => [
            GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
                      "1a4d4fb0c399b261f4ed11aa980c6bab754aefa6")
        ],
        v"7.6.1" => [
            GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
                      "d4dad6c1d0b5cb3e7c5d7d01ef55653713567662")
        ],
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

# Products for the GPU builds of SuiteSparse
gpu_products = [
    LibraryProduct("libcholmod_cuda",                :libcholmod),
    LibraryProduct("libspqr_cuda",                   :libspqr),
    LibraryProduct("libgpuqrengine_cuda",            :libgpuqrengine),
    LibraryProduct("libsuitesparse_gpuruntime_cuda", :libsuitesparse_gpuruntime),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libblastrampoline_jll"; compat="5.8.0"),
    BuildDependency("LLVMCompilerRT_jll",platforms=[Platform("x86_64", "linux"; sanitize="memory")]),
    HostBuildDependency(PackageSpec(; name="CMake_jll", version = v"3.24.3"))
]
