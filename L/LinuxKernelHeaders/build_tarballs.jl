# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Base.BinaryPlatforms
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
KERNEL_FLAGS="ARCH=$(target_to_linux_arch ${encoded_target}) -j${nproc}"
make ${KERNEL_FLAGS} mrproper V=1
make ${KERNEL_FLAGS} INSTALL_HDR_PATH=${prefix} V=1 headers_install

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

function delete_libc_tag(p)
    delete!(tags(p), "libc")
    return p
end

# Collect a set of all linux platforms without a `libc` tag:
platforms = filter(Sys.islinux, supported_platforms(;experimental=true))
platforms = unique(map(delete_libc_tag, platforms))

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


# Somehow, we either need to allow GCC pulling in a LinuxKernelHeaders of a different platform,
# or we need to do this automatically inside of `LinuxKernelHeaders_jll`, because when we built
# LinuxKernelHeaders_jll, we built them with the cross-compilers so they encode _only_ the target
# platform.  We need GCC_jll to be able to pull out "target-matching" platforms, so
# we create duplicate Artifacts.toml mappings for those encoded platforms here.

#=
using Pkg, Pkg.Artifacts, Base.BinaryPlatforms
include(expanduser("~/src/Yggdrasil/fancy_toys.jl"))
artifacts_toml = expanduser("~/.julia/dev/LinuxKernelHeaders_jll/Artifacts.toml")
arts = Artifacts.load_artifacts_toml(artifacts_toml)

# This list of cross_host_platforms should match those in GCC
cross_host_platforms = [
    Platform("x86_64", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="glibc"),
]

for (name, dicts) in arts
    for d in dicts
        if haskey(d, "target_arch")
            continue
        end
        target_platform = Artifacts.unpack_platform(d, "", "")

        for host_platform in cross_host_platforms
            encoded_platform = encode_target_platform(target_platform; host_platform)
            @info(name, target_platform, encoded_platform)
            download_info = [(dl["url"], dl["sha256"]) for dl in d["download"]]
            Artifacts.bind_artifact!(artifacts_toml, name, Base.SHA1(d["git-tree-sha1"]); platform=encoded_platform, download_info)
        end
    end
end
=#