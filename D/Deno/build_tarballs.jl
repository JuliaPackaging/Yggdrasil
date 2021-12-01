# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Deno"
version = v"1.16.3"

release_url = "https://github.com/denoland/deno/releases/download/v$version"
# Collection of sources required to complete build
sources = [
    ArchiveSource("$release_url/deno-x86_64-unknown-linux-gnu.zip", "cf37225189bcc2ac32f80999a59a9325cafe19e9a8de85b6a9c1ec5be2dbc16d"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$release_url/deno-x86_64-apple-darwin.zip", "fa5ff854e5dadee3aadc1007408565b85fd80ab42c6e30d959e51bfee8ee79e5"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$release_url/deno-aarch64-apple-darwin.zip", "bfa9bdaa41f20ace6a8ad862068874583c0dd8c70ebf4064033372bb17981058"; unpack_target="aarch64-apple-darwin20"),
    ArchiveSource("$release_url/deno-x86_64-pc-windows-msvc.zip", "f1de6fda3cd30da44a35cbb3548f85ed9f93b0c8d1973b107810d56e6a6f5318"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$release_url/deno_src.tar.gz", "dd3f8a2f072530aba3d67bc9cc14eb3ee48418ae263ac9dbe37612c16300bd4b"),
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
