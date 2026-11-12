using BinaryBuilder

name = "pixi"
version = v"0.76.2"
gitsha = "c723070a534d675eb809ea637fb486b847c89a56"

# Collection of sources required to build pixi
sources = [
    # the tarballs do not include the license, so we get the repo too
    GitSource("https://github.com/prefix-dev/pixi.git", gitsha, unpack_target="repo"),
    # pre-build tarballs, which only contain the executable
    FileSource(
        "https://github.com/prefix-dev/pixi/releases/download/v$version/pixi-aarch64-apple-darwin.tar.gz",
        "621c771029ecc785dcab3acf1db4671b8b2896e87c87d789160f8ed0d871335c",
        filename="pixi-aarch64-apple-darwin20.tar.gz",
    ),
    FileSource(
        "https://github.com/prefix-dev/pixi/releases/download/v$version/pixi-x86_64-apple-darwin.tar.gz",
        "e4b33400b8aa86b332e52f8eaa30590a78881998d897973439b382ef57ef0458",
        filename="pixi-x86_64-apple-darwin14.tar.gz",
    ),
    FileSource(
        "https://github.com/prefix-dev/pixi/releases/download/v$version/pixi-aarch64-pc-windows-msvc.zip",
        "cc7b2e50b2a81b6e46e55ee576d6319e03a9111400d4b35462a7088e32733c2e",
        filename="pixi-aarch64-w64-mingw32.zip",
    ),
    FileSource(
        "https://github.com/prefix-dev/pixi/releases/download/v$version/pixi-x86_64-pc-windows-msvc.zip",
        "8e948f6b67104be30509ab7d91ac1878fdb7920e57e8b433dbfb7297468b102d",
        filename="pixi-x86_64-w64-mingw32.zip",
    ),
    FileSource(
        "https://github.com/prefix-dev/pixi/releases/download/v$version/pixi-aarch64-unknown-linux-musl.tar.gz",
        "a9e9d021754fc8a849eae10c119ef1a4b51d05f3dc33fbff4fcaec016a8a26dd",
        filename="pixi-aarch64-linux-gnu.tar.gz",
    ),
    FileSource(
        "https://github.com/prefix-dev/pixi/releases/download/v$version/pixi-x86_64-unknown-linux-musl.tar.gz",
        "255f8930c1d68d7d7914253fa56ed6911229980610cac4b5f55334844f6568f7",
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
