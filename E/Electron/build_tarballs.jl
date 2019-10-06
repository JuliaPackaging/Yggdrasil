# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Electron"
version = v"6.0.11"

# Collection of sources required to build Git
binaries_linux = [
    "https://github.com/electron/electron/releases/download/v$(version)/electron-v$(version)-linux-x64.zip" =>
    "be3d3c16957c038fd1ebe6f4675d74a5262a616491237363cd3395942a9273cb"
]

binaries_macos = [
    "https://github.com/electron/electron/releases/download/v$(version)/electron-v$(version)-darwin-x64.zip" =>
    "28819ee428b32d1f8762dac9ce29592b61b425df50337214b00143d7575c2cdc"
]

binaries_w32 = [
    "https://github.com/electron/electron/releases/download/v$(version)/electron-v$(version)-win32-ia32.zip" =>
    "de609b474f2dca7066b920b02305131267b22d8124014cda5682591404b05d23"
]

binaries_w64 = [
    "https://github.com/electron/electron/releases/download/v$(version)/electron-v$(version)-win32-x64.zip" =>
    "adf45c9a410a91167796ab0fff2a2b995e7abadf96a94dc11f96971fd7716da5"
]

# Bash recipe for installing on Windows
script = raw"""
cd $WORKSPACE/srcdir/
cp -r * ${prefix}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [Linux(:x86_64), MacOS(:x86_64), Windows(:i686), Windows(:x86_64)]

# The products that we will ensure are always built
products = [
    ExecutableProduct("electron", :electron),
]

for platform in supported_platforms()
    if platform isa Windows
        if arch(platform) === :i686
            build_tarballs(ARGS, name, version, binaries_w32, script, [platform], products, [])
        else
            build_tarballs(ARGS, name, version, binaries_w64, script, [platform], products, [])
        end
    elseif platform isa MacOS
        build_tarballs(ARGS, name, version, binaries_macos, script, [platform], products, [])
    else
        build_tarballs(ARGS, name, version, sources_unix, script, [platform], products, [])
    end
end