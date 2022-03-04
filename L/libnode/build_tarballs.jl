# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libnode"
version = v"14.17.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://nodejs.org/dist/v14.17.3/node-v14.17.3.tar.gz", "dcbd156506ee79ee48439257626ca0a6db3d7eab8cb0208db6979125ae7d3a95"),
]

host_platform = HostPlatform()


# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd node-*

export CC_host=$HOSTCC
export CXX_host=$HOSTCXX
# Build & install libnode
if [[ $target == $MACHTYPE ]]
then
    ./configure --prefix=${prefix} --shared --without-inspector --no-cross-compiling
else
    DEST_CPU=x86_64
    if [[ $target == *aarch64* ]]; then DEST_CPU=arm64; fi
    DEST_OS=linux
    ./configure --prefix=${prefix} --shared --without-inspector --without-intl --cross-compiling --dest-cpu=$DEST_CPU --dest-os=$DEST_OS
fi

export LDFLAGS=-lrt
export CPPFLAGS=-D__STDC_FORMAT_MACROS
make -j`nproc`
make install
cp ./out/Release/node ${bindir}
install_license ./LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Only 64-bit Linux platforms.
# Requires XCode and MSVC to compile on Mac OS and Windows, respectively.
# TODO: support FreeBSD/Mac/Windows
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),

    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),

    # Platform("x86_64", "macos"),
    # Platform("aarch64", "macos"),

    # Platform("x86_64", "windows"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libnode", :libnode),
    ExecutableProduct("node", :node),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

init_block = raw"""
"""

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS, name, version, sources, script,
    platforms, products, dependencies;
    julia_compat="1.6",
    preferred_gcc_version = v"7",
    init_block = init_block
)
