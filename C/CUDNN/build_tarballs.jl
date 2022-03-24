using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "CUDNN"
version = v"8.3.2"

script = raw"""
mkdir -p ${libdir} ${prefix}/include

cd ${WORKSPACE}/srcdir/cudnn*

install_license LICENSE

if [[ ${target} == powerpc64le-linux-gnu ]]; then
    mv lib/libcudnn*.so* ${libdir}
    mv include/* ${prefix}/include
elif [[ ${target} == *-linux-gnu ]]; then
    mv lib/libcudnn*.so* ${libdir}
    mv include/* ${prefix}/include
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    mv bin/cudnn*64_*.dll ${libdir}
    mv include/* ${prefix}/include

    mv ../dll_x64/zlibwapi.dll ${libdir}

    # fixup
    chmod +x ${libdir}/*.dll
fi
"""

products = [
    LibraryProduct(["libcudnn", "cudnn64_$(version.major)"], :libcudnn, dont_dlopen = true),
]

# XXX: CUDA_loader_jll's CUDA tag should match the library's CUDA version compatibility.
#      lacking that, we can't currently dlopen the library

dependencies = [Dependency(PackageSpec(name="CUDA_loader_jll"))]

cuda_versions = [v"10.2", v"11.0", v"11.1", v"11.2", v"11.3", v"11.4"]
for cuda_version in cuda_versions
    cuda_tag = "$(cuda_version.major).$(cuda_version.minor)"
    include("build_$(cuda_tag).jl")

    for (platform, sources) in platforms_and_sources
        augmented_platform = Platform(arch(platform), os(platform); cuda=cuda_tag)
        should_build_platform(triplet(augmented_platform)) || continue
        if platform == Platform("x86_64", "windows")
            push!(sources,
                ArchiveSource("http://www.winimage.com/zLibDll/zlib123dllx64.zip",
                              "fd324c6923aa4f45a60413665e0b68bb34a7779d0861849e02d2711ff8efb9a4"))
        end
        build_tarballs(ARGS, name, version, sources, script, [augmented_platform],
                       products, dependencies; lazy_artifacts=true)
    end
end
