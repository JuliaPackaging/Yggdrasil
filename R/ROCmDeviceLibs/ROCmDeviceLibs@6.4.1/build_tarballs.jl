using Pkg
using BinaryBuilder

const NAME = "ROCmDeviceLibs"
const ROCM_PLATFORMS = [AnyPlatform()]
# const ROCM_PLATFORMS = [Platform("x86_64", "linux")]
const PRODUCTS = [FileProduct("amdgcn/bitcode/", :bitcode_path)]

# TODO bundle multiple devlibs & select based on Julia LLVM.
const URLS = Dict(
    v"6.4.1" => (
        "https://www.rpmfind.net/linux/fedora/linux/development/rawhide/Everything/x86_64/os/Packages/r/rocm-device-libs-19-9.rocm6.4.1.fc43.x86_64.rpm",
        "6b50adf42ad25e27a9f9a986144882eb88daa54f11c1d7318696a332b4d89b96",
    )
)

function configure_build(version)
    buildscript = raw"""
    apk update
    apk add rpm2cpio

    echo ${prefix}

    cd ${WORKSPACE}/srcdir/

    rpm2cpio rocm-device-libs-19-9.rocm6.4.1.fc43.x86_64.rpm | cpio -idmv
    mv usr/lib64/rocm/llvm/lib/clang/19/amdgcn ${prefix}
    mv usr/share/licenses/rocm-device-libs/LICENSE.TXT ${prefix}
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
