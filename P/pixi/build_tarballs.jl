using BinaryBuilder

name = "pixi"
version = v"0.63.2"
gitsha = "7a53925d6fa0bdc1019d17648f6e6aaa3ee02c9b"

# Collection of sources required to build pixi
sources = [
    # the tarballs do not include the license, so we get the repo too
    GitSource("https://github.com/prefix-dev/pixi.git", gitsha, unpack_target="repo"),
    # pre-build tarballs, which only contain the executable
    FileSource(
        "https://github.com/prefix-dev/pixi/releases/download/v$version/pixi-aarch64-apple-darwin.tar.gz",
        "28fca5e7335b5f6b5b05acb9f83b61fa65e27e5dd69fe7a1750aa884ea4163cb",
        filename="pixi-aarch64-apple-darwin20.tar.gz",
    ),
    FileSource(
        "https://github.com/prefix-dev/pixi/releases/download/v$version/pixi-x86_64-apple-darwin.tar.gz",
        "85ea41d0310acd8e13edf4923b65c101fc3fc5f8d2ee48d85d64f2bcd9781830",
        filename="pixi-x86_64-apple-darwin14.tar.gz",
    ),
    FileSource(
        "https://github.com/prefix-dev/pixi/releases/download/v$version/pixi-aarch64-pc-windows-msvc.zip",
        "7df325a6ca158676a75710e16b20d3b621234852cdc9e733ee9c523b37abc3a9",
        filename="pixi-aarch64-w64-mingw32.zip",
    ),
    FileSource(
        "https://github.com/prefix-dev/pixi/releases/download/v$version/pixi-x86_64-pc-windows-msvc.zip",
        "8a2e31c293ce0a308c2dcf3fae599465bdc97dbd8eefbd320e8ae6cf22de9262",
        filename="pixi-x86_64-w64-mingw32.zip",
    ),
    FileSource(
        "https://github.com/prefix-dev/pixi/releases/download/v$version/pixi-aarch64-unknown-linux-musl.tar.gz",
        "dbde6dbc2806602171e17305ce005e1aed519f2f2461a7cafd0093e92b7e7681",
        filename="pixi-aarch64-linux-gnu.tar.gz",
    ),
    FileSource(
        "https://github.com/prefix-dev/pixi/releases/download/v$version/pixi-x86_64-unknown-linux-musl.tar.gz",
        "b2a9e26bb6c80fe00618a02e7198dec222e1fbcec61e04c11b6e6538089ab100",
        filename="pixi-x86_64-linux-gnu.tar.gz",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

# unpack and install the binary
if [[ $target = *-w64-* ]]; then
    unzip pixi-$target.zip
    install -Dvm 755 pixi.exe "${bindir}/pixi.exe"
else
    tar -xzf pixi-$target.tar.gz
    install -Dvm 755 pixi "${bindir}/pixi"
fi

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
               julia_compat="1.6", lock_microarchitecture=false, lazy_artifacts=true)
