using Pkg
using BinaryBuilder

const NAME = "ROCmDeviceLibs"
const ROCM_PLATFORMS = [AnyPlatform()]
# const ROCM_PLATFORMS = [Platform("x86_64", "linux")]
const PRODUCTS = [FileProduct("amdgcn/bitcode/", :bitcode_path)]

# TODO bundle multiple devlibs & select based on Julia LLVM.
const URLS = Dict(
    v"6.2.1" => (
        "https://www.rpmfind.net/linux/fedora/linux/updates/41/Everything/x86_64/Packages/r/rocm-device-libs-18-10.rocm6.2.1.fc41.x86_64.rpm",
        "e5d6a983fadb89ab8c76d38485198efdbf031cb138a027247c7785d137c32ec0",
    )
)

function configure_build(version)
    buildscript = raw"""
    apk update
    apk add rpm2cpio

    echo ${prefix}

    cd ${WORKSPACE}/srcdir/

    rpm2cpio rocm-device-libs-18-10.rocm6.2.1.fc41.x86_64.rpm | cpio -idmv
    mv usr/lib/clang/18/amdgcn ${prefix}
    mv usr/share/doc/ROCm-Device-Libs/LICENSE.TXT ${prefix}
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
