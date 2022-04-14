# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Base.BinaryPlatforms
include("../../fancy_toys.jl")

name = "LinuxKernelHeaders"
version = v"5.15.14"

# Collection of sources required to build LinuxKernelHeaders
sources = [
    ArchiveSource("https://mirrors.edge.kernel.org/pub/linux/kernel/v$(version.major).x/linux-$(version).tar.xz",
                  "2df2b4e71b5b2f25b201ba5a3d42bdf676b1deaae2fb44c14a1d8a33c9f76a4d"),
]

# Bash recipe for building across all platforms
script = raw"""
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

# Install kernel headers
cd $WORKSPACE/srcdir/linux-*/

# The kernel make system can't deal with spaces (for things like ccache) very well
KERNEL_FLAGS=( "ARCH=$(target_to_linux_arch ${target})" "HOSTCC=${HOSTCC}" "-j${nproc}" )
make ${KERNEL_FLAGS[@]} mrproper V=1
make ${KERNEL_FLAGS[@]} INSTALL_HDR_PATH=${prefix} V=1 headers_install

# Move case-sensitivity issues, breaking netfilter without a patch
NF="${prefix}/include/linux/netfilter"
for NAME in CONNMARK DSCP MARK RATEEST TCPMSS; do
    mv "${NF}/xt_${NAME}.h" "${NF}/xt_${NAME}_.h"
done

for NAME in ECN TTL; do
    mv "${NF}_ipv4/ipt_${NAME}.h" "${NF}_ipv4/ipt_${NAME}_.h"
done
mv "${NF}_ipv6/ip6t_HL.h" "${NF}_ipv6/ip6t_HL_.h"
"""

# We're building cross-artifacts from any platform to all linux platforms:
platforms = filter(Sys.islinux, supported_platforms(;experimental=true))
platforms = unique(map(platforms) do p
    return CrossPlatform(AnyPlatform() => p)
end)

# The products that we will ensure are always built.
# Note that while we place the products directly into `${prefix}`, when using these
# headers with Glibc_jll, GCC_jll, etc... you will most likely want to mount these
# headers at `${compiler_prefix}/${encoded_target}`.
products = Product[
    FileProduct("include/linux/limits.h", :limits_h),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
