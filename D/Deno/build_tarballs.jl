# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Deno"
version = v"1.11.0"

release_url = "https://github.com/denoland/deno/releases/download/v$version"
# Collection of sources required to complete build
sources = [
    ArchiveSource("$release_url/deno-x86_64-unknown-linux-gnu.zip", "dcee5d89abdf35385c2a7f723e38daf22ce7711af7f5a38d1075bb677c6484f7"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$release_url/deno-x86_64-apple-darwin.zip", "f1f5870af3414bde6b2d6973bb96be40a50a4de60024ef4e5883074b0aa4fc57"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$release_url/deno-x86_64-pc-windows-msvc.zip", "b59eb247780c6f1aaf43bfa963fed5ee0c3ac2412341d673ee55ca4ac3825324"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$release_url/deno_src.tar.gz", "3ea1b4ac084fdc79fc8bdb0af0e6d2223f719bfeabbe8f2f556a490fee2b7405"),
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
