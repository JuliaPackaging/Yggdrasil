# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libnode"
version = v"18.12.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://nodejs.org/dist/v$(version)/node-v$(version).tar.gz", "ba8174dda00d5b90943f37c6a180a1d37c861d91e04a4cb38dc1c0c74981c186"),
    ArchiveSource(
        "https://github.com/sunoru/libnode/releases/download/v$(version)/libnode-v$(version)-Windows-x64.zip",
        "675d4b4b335db8d1ab047ea55e09488e0b1c51008f42ee09e4ef7cbca978b2ff",
        unpack_target = "x86_64-w64-mingw32"
    ),
    ArchiveSource(
        "https://github.com/sunoru/libnode/releases/download/v$(version)/libnode-v$(version)-macOS-x64.zip",
        "a19cbfceaeae3e98f982e06dc232f8a228e021941a9ead79aef9bc1ca0fc2f50",
        unpack_target = "x86_64-apple-darwin14"
    ),
    DirectorySource("bundled")
]


w64_script = raw"""
cd ${target}/libnode-*
cd node-*
chmod +x *.cmd *.exe
mkdir -p ${bindir}
mv * ${bindir}/
mv ${bindir}/include ${prefix}
mv ${bindir}/LICENSE .
install_license ./LICENSE
"""

mac_script = raw"""
cd ${target}/libnode-*
chmod +x bin/*
mv * ${prefix}/
mv ${prefix}/LICENSE .
install_license ./LICENSE
"""

linux_script = raw"""
cd node-*
export CC_host=$HOSTCC
export CXX_host=$HOSTCXX
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/configure.py.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/node.gypi.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/node_credentials.cc.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/test_crypto_clienthello.cc.patch"
# Build & install libnode
if [[ $target == $MACHTYPE ]]
then
    ./configure --prefix=${prefix} --shared --no-cross-compiling
else
    DEST_CPU=x86_64
    if [[ $target == *aarch64* ]]; then DEST_CPU=arm64; fi
    ./configure --prefix=${prefix} --shared --cross-compiling --dest-cpu=$DEST_CPU --dest-os=linux
fi

export CPPFLAGS=-D__STDC_FORMAT_MACROS
make -j`nproc`
make install
cp ./out/Release/node ${bindir}
install_license ./LICENSE
"""

# Bash recipe for building across all platforms
script = """
cd \$WORKSPACE/srcdir
if [[ \$target == *w64* ]]
then
    $w64_script
elif [[ \$target == *apple* ]]
then
    $mac_script
elif [[ \$target == *linux* ]]
then
    $linux_script
fi
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

    Platform("x86_64", "macos"),
    # Platform("aarch64", "macos"),

    Platform("x86_64", "windows"),
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
