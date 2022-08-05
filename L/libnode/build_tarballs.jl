# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libnode"
version = v"16.16.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://nodejs.org/dist/v$(version)/node-v$(version).tar.gz", "e07c30b0498f143c08793e34bda1adeaad32f485a4f79f4d67a82879f4c0bbe3"),
    DirectorySource("bundled")
]


# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd node-*

export CC_host=$HOSTCC
export CXX_host=$HOSTCXX
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/node_main.cc.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/trap-handler.h.patch"
# Build & install libnode
if [[ $target == $MACHTYPE ]]
then
    ./configure --prefix=${prefix} --shared --no-cross-compiling
else
    DEST_CPU=x86_64
    if [[ $target == *aarch64* ]]; then DEST_CPU=arm64; fi
    DEST_OS=linux
    ./configure --prefix=${prefix} --shared --cross-compiling --dest-cpu=$DEST_CPU --dest-os=$DEST_OS
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
    preferred_gcc_version = v"9",
    init_block = init_block
)
