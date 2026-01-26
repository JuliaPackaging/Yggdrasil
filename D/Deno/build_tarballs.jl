# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Deno"
version = v"2.6.3"

release_url = "https://github.com/denoland/deno/releases/download/v$version"

# Collection of sources required to complete build
sources = [
    ArchiveSource("$release_url/deno-x86_64-unknown-linux-gnu.zip", "b3c24dc6f3982607896bd795fd6bcbdc53f3d11e8d8190b2a07fd1881eb1148a"; unpack_target="x86_64-linux-gnu"),
    ArchiveSource("$release_url/deno-aarch64-unknown-linux-gnu.zip", "92c9496e8c71e6b18abf1f728d6223bb682749e4946f24589a7ef8972fec423e"; unpack_target="aarch64-linux-gnu"),
    ArchiveSource("$release_url/deno-x86_64-apple-darwin.zip", "3942e5af4d25588b506f49155278239c9fa09e7683a912ca091a346a1fc40733"; unpack_target="x86_64-apple-darwin14"),
    ArchiveSource("$release_url/deno-aarch64-apple-darwin.zip", "7fdc01002a90a6ac58b8936e5d7a872fa7885db71d51bac7f776b7b790c82085"; unpack_target="aarch64-apple-darwin20"),
    ArchiveSource("$release_url/deno-x86_64-pc-windows-msvc.zip", "a011a0c6f1ea120ec60a65969e9d549af894b999cf1d35fe5ee81e694227cce2"; unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("$release_url/deno_src.tar.gz", "f1f631687b9949000b91b480982859a5557b398009f0a6a62d05c88fd4def5fb"),
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
