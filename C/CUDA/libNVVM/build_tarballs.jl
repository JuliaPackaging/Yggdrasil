using BinaryBuilder, Pkg

include("../common.jl")

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "libNVVM"
version = v"4.0.3"
cuda_version = v"12.5.0"

script = raw"""
cd ${WORKSPACE}/srcdir/cuda_nvcc-*
install_license LICENSE

mkdir -p ${bindir} ${libdir} ${prefix}/include ${prefix}/share
if [[ ${target} == *-linux-gnu ]]; then
    mv nvvm/lib64/libnvvm.so* ${libdir}
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    mv nvvm/bin/nvvm64_*.dll ${bindir}
    chmod +x ${bindir}/*.dll
fi
mv nvvm/include/* ${prefix}/include/
mv nvvm/libdevice ${prefix}/share/
"""

platforms = [Platform("x86_64", "linux"),
             Platform("aarch64", "linux"; cuda_platform="jetson"),
             Platform("aarch64", "linux"; cuda_platform="sbsa"),
             Platform("x86_64", "windows")]

products = [
    LibraryProduct(["libnvvm", "nvvm64_40_0"], :libnvvm),
]

dependencies = []

builds = []
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    sources = get_sources("cuda", ["cuda_nvcc"]; version=cuda_version, platform)
    push!(builds, (; platforms=[platform], sources))
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, script,
                   build.platforms, products, dependencies;
                   julia_compat="1.6")
end
