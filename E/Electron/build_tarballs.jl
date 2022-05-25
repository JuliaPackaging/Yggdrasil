using BinaryBuilder

# Collection of sources required to build Electron
name = "Electron"
version = v"16.2.8"

repo_prefix = "https://github.com/electron/electron/releases/download/v$(version)"

sources = [
    # Windows
    ArchiveSource(
        "$(repo_prefix)/electron-v$(version)-win32-ia32.zip",
        "830fc4d7de6307825a409e0f2e8c04219bed68a730d6ac0e74dea4fc883cb76b";
        unpack_target = "i686-w64-mingw32"
    ),
    ArchiveSource(
        "$(repo_prefix)/electron-v$(version)-win32-x64.zip",
        "1ef82d1166875c6f6e02cb4c3bae9f7e5e575f2b61440aba32cd63dcc8b18a27";
        unpack_target = "x86_64-w64-mingw32"
    ),

    # Linux
    ArchiveSource(
        "$(repo_prefix)/electron-v$(version)-linux-x64.zip",
        "68dd612c503a82f9c0ad147e5f1d94213685bfc8fba6c4346fb542ec6fcd14e7";
        unpack_target = "x86_64-linux-gnu"
    ),
    ArchiveSource(
        "$(repo_prefix)/electron-v$(version)-linux-ia32.zip",
        "f00ac4d64bb0c4f6c4c6b317a2a7e5731eb6150f2768ccca2526b41cce612df6";
        unpack_target = "i686-linux-gnu"
    ),
    ArchiveSource(
        "$(repo_prefix)/electron-v$(version)-linux-arm64.zip",
        "29024df822cca9a2bbb2b71d82f2ddf5af5cada80c0bd38e8ede420700297c6a";
        unpack_target = "aarch64-linux-gnu"
    ),
    ArchiveSource(
        "$(repo_prefix)/electron-v$(version)-linux-armv7l.zip",
        "93ba85035ab57537c3388c7b22a7ba66f9c49368aa8fea9816000c3f0f72e513";
        unpack_target = "arm-linux-gnueabihf"
    ),

    # MacOS
    ArchiveSource(
        "$(repo_prefix)/electron-v$(version)-darwin-x64.zip",
        "d40b00dbf2ef0e42f70b5269255101d3978e709dc3f0b6dbe0c7725fc828b3e1";
        unpack_target = "x86_64-apple-darwin14"
    ),
    ArchiveSource(
        "$(repo_prefix)/electron-v$(version)-darwin-arm64.zip",
        "8b68d24e4902c42b934d1b4de2c0e675039d4289a2e9a4caccc6ad13c3faa5ef";
        unpack_target = "aarch64-apple-darwin20"
    ),
]

# Bash recipe for installing on Windows
script = raw"""
ls
cd ${target}
mkdir -p ${bindir}
if [[ $target == *"apple-darwin"* ]]; then
    mv Electron.app/Contents/MacOS/Electron ${bindir}/electron
else
    mv electron${exeext} ${bindir}
fi
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "windows"),
    Platform("i686", "windows"),

    Platform("x86_64", "linux"),
    Platform("i686", "linux"),
    Platform("aarch64", "linux"),
    Platform("armv7l", "linux"),

    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
]
# The products that we will ensure are always built
products = [
    ExecutableProduct("electron", :electron),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
