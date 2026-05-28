using Pkg
using BinaryBuilder

const NAME = "ROCmDeviceLibs"
const ROCM_PLATFORMS = [AnyPlatform()]
# const ROCM_PLATFORMS = [Platform("x86_64", "linux")]
const PRODUCTS = [FileProduct("amdgcn/bitcode/", :bitcode_path)]

# TODO bundle multiple devlibs & select based on Julia LLVM.
const URLS = Dict(
    v"6.4.1" => (
        "https://repo.radeon.com/rocm/apt/6.4.1/pool/main/r/rocm-device-libs6.4.1/rocm-device-libs6.4.1_1.0.0.60401-83~22.04_amd64.deb",
        "13e4efeaedc8f918d36dfd7a542a639ad3c4e5c2f8e03c09cd956c8cfd895422",
    )
)

function configure_build(version)
    buildscript = raw"""
    cd ${WORKSPACE}/srcdir/

    ar x *.deb
    tar xf data.tar.*
    cp -rv $(find opt -type d -name "amdgcn" | head -1) ${prefix}/amdgcn
    install_license opt/rocm-6.4.1/share/doc/ROCm-Device-Libs/LICENSE.TXT
    """

    sources = [FileSource(URLS[version]...)]
    dependencies = []
    NAME, version, sources, buildscript, ROCM_PLATFORMS, PRODUCTS, dependencies
end

build_tarballs(
    ARGS, configure_build(v"6.4.1")...;
    preferred_gcc_version=v"7",
    preferred_llvm_version=v"9",
    julia_compat="1.13")
