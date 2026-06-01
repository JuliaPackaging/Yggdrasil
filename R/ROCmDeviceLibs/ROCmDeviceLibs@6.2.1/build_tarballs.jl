using Pkg
using BinaryBuilder

const NAME = "ROCmDeviceLibs"
const ROCM_PLATFORMS = [AnyPlatform()]
# const ROCM_PLATFORMS = [Platform("x86_64", "linux")]
const PRODUCTS = [FileProduct("amdgcn/bitcode/", :bitcode_path)]

# TODO bundle multiple devlibs & select based on Julia LLVM.
const URLS = Dict(
    v"6.2.1" => (
        "https://repo.radeon.com/rocm/apt/6.2.1/pool/main/r/rocm-device-libs6.2.1/rocm-device-libs6.2.1_1.0.0.60201-112~22.04_amd64.deb",
        "8517fde893bf284b4e8304e51b4829a8d2dd3458b11993081376ff7fbe01acb0",
    )
)

function configure_build(version)
    buildscript = raw"""
    cd ${WORKSPACE}/srcdir/

    ar x *.deb
    tar xf data.tar.*
    cp -rvp $(find opt -type d -name "amdgcn" | head -1) ${prefix}/amdgcn
    install_license opt/rocm-6.2.1/share/doc/ROCm-Device-Libs/LICENSE.TXT
    """

    sources = [FileSource(URLS[version]...)]
    dependencies = []
    NAME, version, sources, buildscript, ROCM_PLATFORMS, PRODUCTS, dependencies
end

build_tarballs(
    ARGS, configure_build(v"6.2.1")...;
    preferred_gcc_version=v"7",
    preferred_llvm_version=v"9",
    julia_compat="1.12")
