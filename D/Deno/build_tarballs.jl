# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Deno"
version = v"2.6.10"

release_url = "https://github.com/denoland/deno/releases/download/v$version"

# Collection of sources required to complete build
sources = [
    ArchiveSource("$release_url/deno-x86_64-unknown-linux-gnu.zip", "92f616d13f4bedabef81e2800340303c6a726e2b7c8eb360d32da82173167254"; unpack_target="x86_64-linux-gnu"),
    ArchiveSource("$release_url/deno-aarch64-unknown-linux-gnu.zip", "ad4031b16b193997cd40d2bf68c9af8b5148e0f39c1e975cfbb6d60ecec19496"; unpack_target="aarch64-linux-gnu"),
    ArchiveSource("$release_url/deno-x86_64-apple-darwin.zip", "549d631ebe2421ee5e16b7a194764ba649ce2d1f4527496c2e607e551b7979b0"; unpack_target="x86_64-apple-darwin14"),
    ArchiveSource("$release_url/deno-aarch64-apple-darwin.zip", "cdc880f43913f105de02a484005e5a5ed030c905e5a67e288f9ecadde6a86f62"; unpack_target="aarch64-apple-darwin20"),
    ArchiveSource("$release_url/deno-x86_64-pc-windows-msvc.zip", "81b3d820d8c8fbb11602be19770b42ea7df6c1cecee9cc53445a5434b55bea95"; unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("$release_url/deno_src.tar.gz", "9d36d89e11b61626d732d71fd5a2b83afba06d02373f1fa8daffff3a0addf936"),
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
