using BinaryBuilder

name = "KernelHeaders"
version = v"4.12" # We'll just use the linux kernel header version here, as it's likely the fastest-moving

# sources to build, such as linux kernel headers, mingw32, osx  our patches, etc....
sources = [
	"https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.12.tar.xz" =>
	"a45c3becd4d08ce411c14628a949d08e2433d8cdeca92036c7013980e93858ab",
    "https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v5.0.4.tar.bz2" =>
    "5527e1f6496841e2bb72f97a184fc79affdcd37972eaa9ebf7a5fd05c31ff803",
    "https://github.com/phracker/MacOSX-SDKs/releases/download/10.13/MacOSX10.10.sdk.tar.xz" =>
    "4a08de46b8e96f6db7ad3202054e28d7b3d60a3d38cd56e61f08fb4863c488ce",
    "https://download.freebsd.org/ftp/releases/amd64/11.1-RELEASE/base.txz" =>
    "62acaee7e7c9df66ee2c0c2d533d1da0ddf67d32833bc4b77d935ddd9fe27dab",
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

## sysroot is where most of this stuff gets plopped
sysroot=${prefix}/${target}/sys-root

if [[ "${target}" == *-linux-* ]]; then
    # First, install kernel headers
    cd $WORKSPACE/srcdir/linux-*/

    # The kernel make system can't deal with spaces (for things like ccache) very well
    KERNEL_FLAGS="ARCH=\\\"$(target_to_linux_arch ${target})\\\" CROSS_COMPILE=\\\"/opt/${target}/bin/${target}-\\\" HOSTCC=\\\"${HOSTCC}\\\""
    eval make ${KERNEL_FLAGS} mrproper V=1
    eval make ${KERNEL_FLAGS} headers_check V=1
    eval make ${KERNEL_FLAGS} INSTALL_HDR_PATH=${sysroot}/usr V=1 headers_install

elif [[ "${target}" == *-mingw* ]]; then
    cd $WORKSPACE/srcdir/mingw-*/mingw-w64-headers
    ./configure --prefix=/ \
        --enable-sdk=all \
        --enable-secure-api \
        --host=${target}

    make install DESTDIR=${sysroot}

elif [[ "${target}" == *-freebsd* ]]; then
    mkdir -p "${sysroot}/usr"
    mv usr/include "${sysroot}/"
    ln -sf "${sysroot}/include" "${sysroot}/usr/"

elif [[ "${target}" == *-apple-* ]]; then
    cd $WORKSPACE/srcdir/MacOSX10.10.sdk
    mkdir -p "${sysroot}"
    mv usr/include "${sysroot}/"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# There is no single product that is reliably created to check.  :/ 
products(prefix) = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
