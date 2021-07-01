# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Deno"
version = v"1.11.4"

release_url = "https://github.com/denoland/deno/releases/download/v$version"
# Collection of sources required to complete build
sources = [
    ArchiveSource("$release_url/deno-x86_64-unknown-linux-gnu.zip", "277fc71be8ecd04b9ae9e4867291b2765ad2f1a2983e94221594a59672e0c5ec"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$release_url/deno-x86_64-apple-darwin.zip", "e46fb730cff11e2adb77e94cf2e83e4c9a491ef49a5396f512327afef99c1217"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$release_url/deno-x86_64-pc-windows-msvc.zip", "b8bfa173e31ee120e7afb180580f9c80fe20d46cc24eeb3455b8b62f982fd408"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$release_url/deno_src.tar.gz", "f760a9fdc61ab2aed904015e8393d625f4d387f04279ae93a3966dbd12f1a8fe"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
install_license deno/LICENSE.md
mkdir "${bindir}"
install -m 755 "${target}/deno${exeext}" "${bindir}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),
] 

# The products that we will ensure are always built
products = [
    ExecutableProduct("deno", :deno)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
