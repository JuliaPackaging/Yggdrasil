# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Deno"
version = v"1.9.2"

release_url = "https://github.com/denoland/deno/releases/download/v$version"
# Collection of sources required to complete build
sources = [
    ArchiveSource("$release_url/deno-x86_64-unknown-linux-gnu.zip", "05c69483ff0b98c7b26666e35672b71f3dcde1df523db10ccee60510275be1c5"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$release_url/deno-x86_64-apple-darwin.zip", "6facc63a33c575a016ec51c911ea0c1f09d51021d42b57d610a2185f26974bae"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$release_url/deno-x86_64-pc-windows-msvc.zip", "2725784bbccbef854b18ff25d4cf5ef6e0e85be783973edabad62d785fa009e3"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$release_url/deno_src.tar.gz", "555d928670a147e7048685ab8bcb75bc96237bd2511965d4d897ed4bb52e0373"),
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
    Platform("x86_64", "linux"; cxxstring_abi="cxx11"),
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
