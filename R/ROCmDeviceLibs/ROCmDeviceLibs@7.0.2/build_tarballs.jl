using Pkg
using BinaryBuilder

const NAME = "ROCmDeviceLibs"
const ROCM_PLATFORMS = [AnyPlatform()]
# const ROCM_PLATFORMS = [Platform("x86_64", "linux")]
const PRODUCTS = [FileProduct("amdgcn/bitcode/", :bitcode_path)]

# TODO bundle multiple devlibs & select based on Julia LLVM.
const URLS = Dict(
    v"7.0.2" => (
                 "https://www.rpmfind.net/linux/fedora/linux/development/rawhide/Everything/x86_64/os/Packages/r/rocm-device-libs-20-4.rocm7.0.2.fc44.x86_64.rpm",
                 "d9e430f3992ec2823b1ccc59e661133f7ee02bb0af1f5b9a8542245bf024cd34",
    )
)

function configure_build(version)
    buildscript = raw"""
    apk update
    apk add rpm2cpio

    cd ${WORKSPACE}/srcdir/

    prefix="${WORKSPACE}/destdir"

    rpm2cpio rocm-device-libs-20-4.rocm7.0.2.fc44.x86_64.rpm | cpio -idmv
    mv usr/lib64/rocm/llvm/lib/clang/20/amdgcn ${WORKSPACE}/destdir
    install_license usr/share/licenses/rocm-device-libs/LICENSE.TXT
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
