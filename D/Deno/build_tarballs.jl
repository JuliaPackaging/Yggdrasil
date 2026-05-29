# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Deno"
version = v"2.8.1"

release_url = "https://github.com/denoland/deno/releases/download/v$version"

# Collection of sources required to complete build
sources = [
    ArchiveSource("$release_url/deno-x86_64-unknown-linux-gnu.zip", "2d7bb6195226ac832e0bf7109a115f0af65ee69ac797a4bbde5b27a06cc242d9"; unpack_target="x86_64-linux-gnu"),
    ArchiveSource("$release_url/deno-aarch64-unknown-linux-gnu.zip", "67e9df91870fd0af700df924173e3009ea7ff6956e2c3c3bb86065d6070d0fd6"; unpack_target="aarch64-linux-gnu"),
    ArchiveSource("$release_url/deno-x86_64-apple-darwin.zip", "47473845e0522ba11dd279e3dd318e2d84ee200c56b8280594e0ae0b0f827460"; unpack_target="x86_64-apple-darwin14"),
    ArchiveSource("$release_url/deno-aarch64-apple-darwin.zip", "8154e2de0ee8c1cae31fa88e078724aaef0295fab9fd2ad6f8520389cee908f6"; unpack_target="aarch64-apple-darwin20"),
    ArchiveSource("$release_url/deno-x86_64-pc-windows-msvc.zip", "5fb5bac71f609fb91ec8960fb290885aadc27eeb22f07a8eca0c3db6be38b11a"; unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("$release_url/deno_src.tar.gz", "062d821f7d8bdb6ccbc79a5b1625b2a3f3378f187fc78018a77eada32d5fcd6c"),
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
