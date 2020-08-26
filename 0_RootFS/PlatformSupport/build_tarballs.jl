using BinaryBuilder, Dates, Pkg
include("../common.jl")

# Don't mount any shards that you don't need to
Core.eval(BinaryBuilder, :(bootstrap_list = [:rootfs]))

compiler_target = platform_key_abi(ARGS[end])
if isa(compiler_target, UnknownPlatform)
    error("This is not a typical build_tarballs.jl!  Must provide exactly one platform as the last argument!")
end
deleteat!(ARGS, length(ARGS))
name = "PlatformSupport"
version = VersionNumber("$(year(today())).$(month(today())).$(day(today()))")

sources = [
    ArchiveSource("https://mirrors.edge.kernel.org/pub/linux/kernel/v4.x/linux-4.20.9.tar.xz",
                  "b5de28fd594a01edacd06e53491ad0890293e5fbf98329346426cf6030ef1ea6"),
    ArchiveSource("https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v7.0.0.tar.bz2",
                  "aa20dfff3596f08a7f427aab74315a6cb80c2b086b4a107ed35af02f9496b628"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.12.sdk.tar.xz",
                  "6852728af94399193599a55d00ae9c4a900925b6431534a3816496b354926774"),
    ArchiveSource("https://download.freebsd.org/ftp/releases/amd64/11.4-RELEASE/base.txz",
                  "3bac8257bdd5e5b071f7b80cc591ebecd01b9314ca7839a2903096cbf82169f9"),
    ArchiveSource("https://github.com/llvm/llvm-project/releases/download/llvmorg-8.0.1/libcxx-8.0.1.src.tar.xz",
                  "7f0652c86a0307a250b5741ab6e82bb10766fb6f2b5a5602a63f30337e629b78"),
    DirectorySource("./bundled"),
]

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
        cd $WORKSPACE/srcdir/mingw-*/mingw-w64-headers
        ./configure --prefix=/ \
            --enable-sdk=all \
            --enable-secure-api \
            --host=${COMPILER_TARGET}

        make install DESTDIR=${sysroot}
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
        apk add gcc g++ musl-dev

        # Also deploy libcxx headers
        cd ${WORKSPACE}/srcdir/libcxx*
        mkdir build && cd build
        PREFIX="${sysroot}" cmake .. -DLLVM_ENABLE_PROJECTS='libcxx' \
                 -DCMAKE_INSTALL_PREFIX="${sysroot}/usr" \
                 -DCMAKE_CROSSCOMPILING=True \
                 -DLLVM_HOST_TRIPLE=${COMPILER_TARGET} \
                 -DDARWIN_macosx_CACHED_SYSROOT:STRING="${sysroot}" \
                 -DDARWIN_osx_ARCHS=x86_64
        make install-cxx-headers
        ;;
    *)
        echo "ERROR: Unmatched platform!" >&2
        exit 1
        ;;
esac

# Install cmake templates
cd ${WORKSPACE}/srcdir/buildsystem_toolchains
./build_toolchains.sh ${COMPILER_TARGET}
mv ${COMPILER_TARGET}/* ${prefix}

# We create a link from ${COMPILER_TARGET}/sys-root/usr/local to ${prefix}.
# This is the most reliable way for our sysroot'ed compilers to find destination
# libraries so far, hopefully this changes in the future.
mkdir -p "${sysroot}/usr"
ln -s "${prefix}" "${sysroot}/usr/local"
"""

# Build the artifacts
ndARGS = filter(x -> !occursin("--deploy", x), ARGS)
build_info = build_tarballs(ndARGS, "$(name)-$(triplet(compiler_target))", version, sources, script, [host_platform], Product[], []; skip_audit=true)

if any(occursin.("--deploy", ARGS))
    upload_and_insert_shards("JuliaPackaging/Yggdrasil", name, version, build_info; target=compiler_target)
end
