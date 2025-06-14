# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Deno"
version = v"2.2.6"

release_url = "https://github.com/denoland/deno/releases/download/v$version"

# Collection of sources required to complete build
sources = [
    ArchiveSource("$release_url/deno-x86_64-unknown-linux-gnu.zip", "2bc96c49f5ceb5a74add43f16381e2a2ab5f509c5a5665c5533a661a4141e650"; unpack_target="x86_64-linux-gnu"),
    ArchiveSource("$release_url/deno-aarch64-unknown-linux-gnu.zip", "6fbb81191c38488de73f4a8612d856d4eeb45165121dd57c6f68a46de82d30aa"; unpack_target="aarch64-linux-gnu"),
    ArchiveSource("$release_url/deno-x86_64-apple-darwin.zip", "85eaa0d3f8e76931ca4b03f3d5befcb2ad72942db2a3233e3abf2dab58db52bc"; unpack_target="x86_64-apple-darwin14"),
    ArchiveSource("$release_url/deno-aarch64-apple-darwin.zip", "4459182bd23c28958c807f06645e371ec8a34cddb70a1d99680e75cca76d6e86"; unpack_target="aarch64-apple-darwin20"),
    ArchiveSource("$release_url/deno-x86_64-pc-windows-msvc.zip", "e0229e239b4b3ffd356a7731dcab9e277c7750669c27515c4c22cd21b1c0108d"; unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("$release_url/deno_src.tar.gz", "e3a0763f10d8f0ec511f2617456c7e0eee130c2b7a6787abbbab3baf29bc98e8"),
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
