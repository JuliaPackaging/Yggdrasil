# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Deno"
version = v"1.33.4"

release_url = "https://github.com/denoland/deno/releases/download/v$version"
release_arm_url = "https://github.com/LukeChannings/deno-arm64/releases/download/v$version"
# Collection of sources required to complete build
sources = [
    ArchiveSource("$release_url/deno-x86_64-unknown-linux-gnu.zip", "2e62448732a8481cae7af6637ddd37289e5baa6f22cd8e2f8197e25991869257"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$release_arm_url/deno-linux-arm64.zip", "13aa4b3e5f652be2e436798105e5e4a48dbfd398cfc297384e9708a43c9b3337"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$release_url/deno-x86_64-apple-darwin.zip", "1e2d79b4a237443e201578fc825052245d2a71c9a17e2a5d1327fa35f9e8fc0e"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$release_url/deno-aarch64-apple-darwin.zip", "ea504cac8ba53ef583d0f912d7834f4bff88eb647cfb10cb1dd24962b1dc062d"; unpack_target="aarch64-apple-darwin20"),
    ArchiveSource("$release_url/deno-x86_64-pc-windows-msvc.zip", "f66842f3ed2b906f0db503b2eebd53c87240ade0dd3045919a7a2ba12962c0e4"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$release_url/deno_src.tar.gz", "d7d4d525e4f8973a23754654925b14f2a215baff4d3dd183e75047a3dac957ac"),
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
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
