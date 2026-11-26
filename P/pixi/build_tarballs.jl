using BinaryBuilder

name = "pixi"
version = v"0.84.2"
gitsha = "98cc736a9ba6e7e15f19abd59ff45ba805f712bd"

# Collection of sources required to build pixi
sources = [
    # the tarballs do not include the license, so we get the repo too
    GitSource("https://github.com/prefix-dev/pixi.git", gitsha; tag="v$(version)", unpack_target="repo"),
    # pre-build tarballs, which only contain the executable
    FileSource(
        "https://github.com/prefix-dev/pixi/releases/download/v$version/pixi-aarch64-apple-darwin.tar.gz",
        "039d4b48c7e17bc62a36faa2af1b13d0d187f5dd6e8fea17e0587302438df6e6",
        filename="pixi-aarch64-apple-darwin20.tar.gz",
    ),
    FileSource(
        "https://github.com/prefix-dev/pixi/releases/download/v$version/pixi-x86_64-apple-darwin.tar.gz",
        "a633a4f8276955b73248397c17ce77380eb7133dc96c54bc271239b7dc9b8837",
        filename="pixi-x86_64-apple-darwin14.tar.gz",
    ),
    FileSource(
        "https://github.com/prefix-dev/pixi/releases/download/v$version/pixi-aarch64-pc-windows-msvc.zip",
        "2c8d16e4f1a3600e587c0157ddb25f9a046b41da275e2125f0384e94841a45e6",
        filename="pixi-aarch64-w64-mingw32.zip",
    ),
    FileSource(
        "https://github.com/prefix-dev/pixi/releases/download/v$version/pixi-x86_64-pc-windows-msvc.zip",
        "aa4f02efac31566176d639007e65a36740aa7b56c22673c44ecfd2611e7a6b2c",
        filename="pixi-x86_64-w64-mingw32.zip",
    ),
    FileSource(
        "https://github.com/prefix-dev/pixi/releases/download/v$version/pixi-aarch64-unknown-linux-musl.tar.gz",
        "0957b6352d077bb3ffcce913f90b1e6cfbc6b98888a45d59ee2910e8c4811110",
        filename="pixi-aarch64-linux-gnu.tar.gz",
    ),
    FileSource(
        "https://github.com/prefix-dev/pixi/releases/download/v$version/pixi-x86_64-unknown-linux-musl.tar.gz",
        "6d2a576bde0a7b26533a068fec0aea6e4ee21c36668efc1dc73fce90110906ae",
        filename="pixi-x86_64-linux-gnu.tar.gz",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

# unpack and install the binary
if [[ $target = *-w64-* ]]; then
    unzip pixi-$target.zip
else
    tar -xzf pixi-$target.tar.gz
fi
install -Dvm 755 "pixi${exeext}" -t "${bindir}"

# install the license
install_license repo/pixi/LICENSE
"""

# Supported platforms from https://github.com/prefix-dev/pixi/releases/latest
platforms = [
    # apple
    Platform("aarch64", "macos"),
    Platform("x86_64", "macos"),
    # windows
    # Platform("aarch64", "windows"),  # not supported by julia
    Platform("x86_64", "windows"),
    # linux
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("pixi", :pixi),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", lazy_artifacts=true)
