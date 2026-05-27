using Pkg
using BinaryBuilder

const NAME = "ROCmDeviceLibs"
const ROCM_PLATFORMS = [AnyPlatform()]
# const ROCM_PLATFORMS = [Platform("x86_64", "linux")]
const PRODUCTS = [FileProduct("amdgcn/bitcode/", :bitcode_path)]

# TODO bundle multiple devlibs & select based on Julia LLVM.
const URLS = Dict(
    v"7.0.2" => (
                 "https://repo.radeon.com/rocm/apt/7.0.2/pool/main/r/rocm-device-libs7.0.2/rocm-device-libs7.0.2_1.0.0.70002-56~22.04_amd64.deb",
                 "536f54c9073c1d88d7583c61e4ca6436d491dac850d7268c4185df51947bd01d",
    )
)

function configure_build(version)
    buildscript = raw"""
    cd ${WORKSPACE}/srcdir/

    ar x *.deb
    tar xf data.tar.*
    mkdir -p ${WORKSPACE}/destdir/amdgcn
    install -Dv opt/rocm-7.0.2/lib/llvm/lib/clang/20/lib/amdgcn/* ${WORKSPACE}/destdir/amdgcn
    install_license opt/rocm-7.0.2/share/doc/ROCm-Device-Libs/LICENSE.TXT
    """

    sources = [FileSource(URLS[version]...)]
    dependencies = []
    NAME, version, sources, buildscript, ROCM_PLATFORMS, PRODUCTS, dependencies
end

build_tarballs(
    ARGS, configure_build(v"7.0.2")...;
    preferred_gcc_version=v"7",
    preferred_llvm_version=v"9",
    julia_compat="1.13")
