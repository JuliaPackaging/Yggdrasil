using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "cuQuantum"
version_string = "22.07.1.14"
version = let
    maj, min, patch, extra = parse.(Int, split(version_string, '.'))
    VersionNumber(maj, min, patch * 100 + extra)
end

platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cuquantum/redist/cuquantum/linux-x86_64/cuquantum-linux-x86_64-$(version_string)-archive.tar.xz",
                      "4c4931096498451593ad553b6cb7a107bb6d6cedea65c80d5376d0cfbb647f8e")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cuquantum/redist/cuquantum/linux-ppc64le/cuquantum-linux-ppc64le-$(version_string)-archive.tar.xz",
                      "2d35dba3c739e8de51591bcd2d7edf1a3c9995850af6525ae08e9b5c3798cf9a")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cuquantum/redist/cuquantum/linux-sbsa/cuquantum-linux-sbsa-$(version_string)-archive.tar.xz",
                      "0c8fb14bf8916170e15a2ae7cfa950e23af13c9cb0915bad88d754221ad60116")],
)

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/cuquantum-*

mkdir -p ${prefix}
cp -var lib/ include/ ${prefix}
cp -var pkg-config/ ${prefix}/lib

# Fixup pkg-config files
sed -i \
    -e "s?^cudaroot=.*?cudaroot=${prefix}?" \
    -e "s?^libdir=.*?libdir=${libdir}?" \
    -e "s?^includedir=.*?includedir=${includedir}?" \
    ${libdir}/pkg-config/*.pc

# Remove static libraries
rm ${libdir}/*.a

# Install license files
install_license LICENSE docs/*
"""

augment_platform_block = CUDA.augment

dependencies = [
    RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll")),
    RuntimeDependency(PackageSpec(name="CUTENSOR_jll"), compat="~1.6")
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libcustatevec", :libcustatevec),
    LibraryProduct("libcutensornet", :libcutensornet),
]

# Build the tarballs, and possibly a `build.jl` as well.
for (platform, sources) in platforms_and_sources
    augmented_platform = Platform(arch(platform), os(platform);
                                  cuda=CUDA.platform(v"11"))
    should_build_platform(triplet(augmented_platform)) || continue
    build_tarballs(ARGS, name, version, sources, script, [augmented_platform],
                   products, dependencies; lazy_artifacts=true,
                   julia_compat="1.6", augment_platform_block,
                   skip_audit=true, dont_dlopen=true)
end
