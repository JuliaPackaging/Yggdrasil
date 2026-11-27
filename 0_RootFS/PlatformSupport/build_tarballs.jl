### Instructions for adding a new version
#
# Check out a branch of BinaryBuilderBase from the current master of that repo.
# Run this script for each target platform. The following will do the job:
# ```
# using BinaryBuilder
# using BinaryBuilder: aatriplet
# for platform in supported_platforms()
#     # Append version numbers for BSD systems
#     if Sys.isapple(platform)
#         suffix = "20"
#     elseif Sys.isfreebsd(platform)
#         suffix = "14.1"
#     else
#         suffix = ""
#     end
#     target = aatriplet(platform) * suffix
#     run(`$(Base.julia_cmd()) build_tarballs.jl --debug --verbose --deploy $target`)
# end
# ```
# (Note that `--deploy` requires a GitHub personal access token in a `GITHUB_TOKEN`
# environment variable with write access to Yggdrasil.)
# Running this will update BinaryBuilderBase/Artifacts.toml with the entries formatted as
# `PlatformSupport-<target triplet>.v<today's date>.<builder triplet>.<squashfs|unpacked>`.
# You can open a PR to BinaryBuilderBase with this change and update the default
# PlatformSupport version to use in `choose_shards` to be `v<today's date>`.

using BinaryBuilder, Dates, Pkg, Base.BinaryPlatforms
using BinaryBuilderBase: AbstractSource
include("../common.jl")

# Don't mount any shards that you don't need to
@eval BinaryBuilder.BinaryBuilderBase empty!(bootstrap_list)
@eval BinaryBuilder.BinaryBuilderBase push!(bootstrap_list, :rootfs)

compiler_target = try
    parse(Platform, ARGS[end])
catch
    error("This is not a typical build_tarballs.jl!  Must provide exactly one platform as the last argument!")
end
deleteat!(ARGS, length(ARGS))
name = "PlatformSupport"
version = VersionNumber("$(year(today())).$(month(today())).$(day(today()))")

# Add check that FreeBSD and MacOS shards have version numbers embedded
if (Sys.isapple(compiler_target) || Sys.isfreebsd(compiler_target)) && os_version(compiler_target) === nothing
    error("Compiler target $(triplet(compiler_target)) does not have an `os_version` tag!")
end

sources = AbstractSource[]

if Sys.islinux(compiler_target)
    push!(sources,
          ArchiveSource("https://mirrors.edge.kernel.org/pub/linux/kernel/v4.x/linux-4.20.9.tar.xz",
                        "b5de28fd594a01edacd06e53491ad0890293e5fbf98329346426cf6030ef1ea6"))
end

if Sys.isfreebsd(compiler_target)
    push!(sources, freebsd_base_source(compiler_target))
end

if Sys.isapple(compiler_target)
    push!(sources,
          ArchiveSource("https://github.com/llvm/llvm-project/releases/download/llvmorg-8.0.1/libcxx-8.0.1.src.tar.xz",
                        "7f0652c86a0307a250b5741ab6e82bb10766fb6f2b5a5602a63f30337e629b78"))
    push!(sources, macos_sdk_source(compiler_target))
end

script = "COMPILER_TARGET=$(BinaryBuilder.aatriplet(compiler_target))\n" * raw"""
## Function to take in a target such as `aarch64-linux-gnu`` and spit out a
## linux kernel arch like "arm64".
target_to_linux_arch()
{
    case "$1" in
        arm*)
            echo "arm"
            ;;
        aarch64*)
            echo "arm64"
            ;;
        powerpc*)
            echo "powerpc"
            ;;
        riscv64*)
            echo "riscv"
            ;;
        i686*)
            echo "x86"
            ;;
        x86*)
            echo "x86"
            ;;
    esac
}

## sysroot is where most of this stuff gets plopped
sysroot=${prefix}/${COMPILER_TARGET}/sys-root

# Install kernel headers
case "${COMPILER_TARGET}" in
    *-linux-*)
        cd $WORKSPACE/srcdir/linux-*/

        # Grumble, grumble, need gcc just to install some headers...
        apk update
        apk add gcc musl-dev

        # The kernel make system can't deal with spaces (for things like ccache) very well
        KERNEL_FLAGS="ARCH=$(target_to_linux_arch ${COMPILER_TARGET}) -j${nproc}"
        make ${KERNEL_FLAGS} mrproper V=1
        make ${KERNEL_FLAGS} headers_check V=1
        make ${KERNEL_FLAGS} INSTALL_HDR_PATH=${sysroot}/usr V=1 headers_install

        # Move case-sensitivity issues, breaking netfilter without a patch
        NF="${prefix}/${COMPILER_TARGET}/sys-root/usr/include/linux/netfilter"
        for NAME in CONNMARK DSCP MARK RATEEST TCPMSS; do
            mv "${NF}/xt_${NAME}.h" "${NF}/xt_${NAME}_.h"
        done

        for NAME in ECN TTL; do
            mv "${NF}_ipv4/ipt_${NAME}.h" "${NF}_ipv4/ipt_${NAME}_.h"
        done
        mv "${NF}_ipv6/ip6t_HL.h" "${NF}_ipv6/ip6t_HL_.h"
        ;;

    *-mingw*)
        ;;

    *-freebsd*)
        mkdir -p "${sysroot}/usr"
        mv usr/include "${sysroot}/"
        ln -sf "../include" "${sysroot}/usr/include"
        ;;

    *-apple-*)
        cd ${WORKSPACE}/srcdir/MacOSX*.sdk
        mkdir -p "${sysroot}/usr"
        mv usr/include "${sysroot}/usr"
        mv System "${sysroot}/"

        # Grumble, grumble, need gcc just to install some headers...
        apk update
        apk add gcc g++ musl-dev

        # Also deploy libcxx headers
        cd ${WORKSPACE}/srcdir/libcxx*
        mkdir build && cd build
        PREFIX="${sysroot}" cmake .. -DLLVM_ENABLE_PROJECTS='libcxx' \
                 -DCMAKE_INSTALL_PREFIX="${sysroot}/usr" \
                 -DCMAKE_CROSSCOMPILING=True \
                 -DLLVM_HOST_TRIPLE=${COMPILER_TARGET} \
                 -DDARWIN_macosx_CACHED_SYSROOT:STRING="${sysroot}"
        make install-cxx-headers
        ;;
    *)
        echo "ERROR: Unmatched platform!" >&2
        exit 1
        ;;
esac

# We create a link from ${COMPILER_TARGET}/sys-root/usr/local to ${prefix}.
# This is the most reliable way for our sysroot'ed compilers to find destination
# libraries so far, hopefully this changes in the future.
mkdir -p "${sysroot}/usr"
ln -s "${prefix}" "${sysroot}/usr/local"
"""

# Build the artifacts
ndARGS, deploy_target = find_deploy_arg(ARGS)
build_info = build_tarballs(ndARGS, "$(name)-$(triplet(compiler_target))", version, sources, script, [host_platform], Product[], [];
                            skip_audit=true, validate_name=false)
if deploy_target !== nothing
    upload_and_insert_shards(deploy_target, name, version, build_info; target=compiler_target)
end
