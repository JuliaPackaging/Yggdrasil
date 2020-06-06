using BinaryBuilder
using Pkg

name = "Darknet_CUDA"

include("../common.jl")

version, sources, script, products, dependencies = gen_common(; gpu = true)

push!(sources,
      [
          ArchiveSource("https://github.com/JuliaGPU/CUDABuilder/releases/download/v0.3.0/CUDNN+CUDA10.1.v7.6.5.x86_64-linux-gnu.tar.gz", "79de5b5085a33bc144b87028e998a1d295a15c3424d6d45b25defe500f616974", unpack_target = "cudnn"),
          DirectorySource("./bundled"),
      ]...)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc, compiler_abi = CompilerABI(cxxstring_abi = :cxx11)),
]

push!(dependencies, BuildDependency(PackageSpec(name="CUDA_full_jll")))

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
