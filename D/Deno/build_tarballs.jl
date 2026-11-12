# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Deno"
version = v"2.9.8"

release_url = "https://github.com/denoland/deno/releases/download/v$version"

# Collection of sources required to complete build
sources = [
    ArchiveSource("$release_url/deno-x86_64-unknown-linux-gnu.zip", "e890975bc2549807bbcc0b584ffafda72cc7c93349dd99c80483dd784f6c4609"; unpack_target="x86_64-linux-gnu"),
    ArchiveSource("$release_url/deno-aarch64-unknown-linux-gnu.zip", "d49596c20b9788cf8f5d8ddf644103d4bde56ed239753f0bdb92ba9361d51905"; unpack_target="aarch64-linux-gnu"),
    ArchiveSource("$release_url/deno-x86_64-apple-darwin.zip", "4b2f5edd2639b7470f034238b321d7002d8dfb4726d8558f52c17afac370eb2c"; unpack_target="x86_64-apple-darwin14"),
    ArchiveSource("$release_url/deno-aarch64-apple-darwin.zip", "9f0bf660393da2eaff044cdc7444cb08c73f235849b61d224d825a194ce7c98e"; unpack_target="aarch64-apple-darwin20"),
    ArchiveSource("$release_url/deno-x86_64-pc-windows-msvc.zip", "cba84b26e0df5ae7f74fc66b86a95b866872a86292ebd84fa1e959927edd93bf"; unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("$release_url/deno_src.tar.gz", "b57d0281c1647effc735f242ba52bc409747fc6ed6ad4946e76f062c67e113eb"),
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
