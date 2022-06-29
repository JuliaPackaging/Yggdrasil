# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Deno"
version = v"1.20.4"

release_url = "https://github.com/denoland/deno/releases/download/v$version"
# Collection of sources required to complete build
sources = [
    ArchiveSource("$release_url/deno-x86_64-unknown-linux-gnu.zip", "c77f735729611deaf6300a8aca4c2049debc29f612e78acdd91c2adce648079e"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$release_url/deno-x86_64-apple-darwin.zip", "6f7490795e9ef28b65b1a3dbdaacd9e625b4f158ca0bd5f37ea97baf8ec31c13"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$release_url/deno-aarch64-apple-darwin.zip", "4fce74da80649fe4eac866f14b6ae202bce3a22118b8df3157023800c209b64b"; unpack_target="aarch64-apple-darwin20"),
    ArchiveSource("$release_url/deno-x86_64-pc-windows-msvc.zip", "bcc5acd083f8991977535c70290ba572bb38474551fc0798016c0c43039e880d"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$release_url/deno_src.tar.gz", "921aff769d9e54e30a33fb80dfe6db5b9bfc464cfc041083d9f17a78662bd1ac"),
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
