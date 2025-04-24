# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Bun"
version = v"1.2.10"

release_url = "https://github.com/oven-sh/bun/releases/download/bun-v$version"
# Collection of sources required to complete build
sources = [
    ArchiveSource("$release_url/bun-linux-x64.zip", "68a154ff1be96851b4d1a87cc5197f027ef80ab79afa3d4587150fae5c34c36e"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$release_url/bun-linux-aarch64.zip", "54592fd0237e3ec91a2933dff015e15a78989d97234042e7d5334a4c0ad50603"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$release_url/bun-darwin-x64.zip", "3443df70c763665db70267c6e883d312c922ccb54a085a40645e7d5603ba9b59"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$release_url/bun-darwin-aarch64.zip", "07895ef0fb661249b86b0b723b65b1cc4790c7f3685b63cda90122b00299972c"; unpack_target="aarch64-apple-darwin20"),
    ArchiveSource("$release_url/bun-windows-x64.zip", "e936fcfacb3cdd823f4fd60402920f52219cfe1dd970eb5650656f67a5ee9109"; unpack_target = "x86_64-w64-mingw32"),
    GitSource("https://github.com/oven-sh/bun.git", "db2e7d7f748dd3951ac0c983de73e75df51bb735"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
install_license bun/LICENSE.md
mkdir "${bindir}"
install -m 755 "${target}/*/bun${exeext}" "${bindir}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
] 

# The products that we will ensure are always built
products = [
    ExecutableProduct("bun", :bun)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
