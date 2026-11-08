using BinaryBuilder2

# The Linux kernel's userspace API headers, which BinaryBuilder2's `*-linux-*` C toolchains
# install into their sysroot (`<sysroot>/usr`) and build glibc, musl and GCC against.
version = v"6.9.5"

build_tarballs(;
    src_name = "LinuxKernelHeaders",
    src_version = version,
    sources = [
        ArchiveSource([
                "https://cdn.kernel.org/pub/linux/kernel/v$(version.major).x/linux-$(version).tar.xz",
                "https://mirrors.edge.kernel.org/pub/linux/kernel/v$(version.major).x/linux-$(version).tar.xz",
            ],
            "a51fb4ab5003a6149bd9bf4c18c9b1f0f4945c272549095ab154b9d1052f95b1"),
    ],
    script = raw"""
    # Map a target triplet such as `aarch64-linux-gnu` to a kernel `ARCH` such as `arm64`
    target_to_linux_arch()
    {
        case "$1" in
            arm*)
                echo "arm" ;;
            aarch64*)
                echo "arm64" ;;
            powerpc*)
                echo "powerpc" ;;
            i686*|x86_64*)
                echo "x86" ;;
        esac
    }

    cd ${WORKSPACE}/srcdir/linux-*/

    # The kernel's make system doesn't cope with spaces in variables (e.g. from ccache),
    # so pass these as separate words
    KERNEL_FLAGS=( "ARCH=$(target_to_linux_arch ${target})" "HOSTCC=${HOSTCC}" "-j${nproc}" )
    make "${KERNEL_FLAGS[@]}" mrproper V=1
    make "${KERNEL_FLAGS[@]}" INSTALL_HDR_PATH=${prefix} V=1 headers_install

    # Some netfilter headers differ from others only in case (e.g. `xt_MARK.h` and `xt_mark.h`),
    # which breaks extraction on case-insensitive filesystems; rename the upper-case ones.
    NF="${prefix}/include/linux/netfilter"
    for NAME in CONNMARK DSCP MARK RATEEST TCPMSS; do
        mv "${NF}/xt_${NAME}.h" "${NF}/xt_${NAME}_.h"
    done
    for NAME in ECN TTL; do
        mv "${NF}_ipv4/ipt_${NAME}.h" "${NF}_ipv4/ipt_${NAME}_.h"
    done
    mv "${NF}_ipv6/ip6t_HL.h" "${NF}_ipv6/ip6t_HL_.h"

    install_license COPYING LICENSES/preferred/GPL-2.0 LICENSES/exceptions/Linux-syscall-note
    """,
    platforms = [
        Platform("x86_64", "linux"),
        Platform("i686", "linux"),
        Platform("armv7l", "linux"),
        Platform("armv6l", "linux"),
        Platform("aarch64", "linux"),
        Platform("powerpc64le", "linux"),

        Platform("x86_64", "linux"; libc="musl"),
        Platform("i686", "linux"; libc="musl"),
        Platform("armv7l", "linux"; libc="musl"),
        Platform("armv6l", "linux"; libc="musl"),
        Platform("aarch64", "linux"; libc="musl"),
    ],
    products = [
        FileProduct("\${includedir}/linux/limits.h", :limits_h),
    ],
    # Use the bootstrap toolchain, since this is part of building the toolchain itself
    host_toolchains = [CToolchain(;vendor=:bootstrap), HostToolsToolchain()],
    target_toolchains = [CToolchain(;vendor=:bootstrap)],
)
