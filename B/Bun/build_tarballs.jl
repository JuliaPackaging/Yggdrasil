# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Bun"
version = v"1.2.10"

release_url = "https://github.com/oven-sh/bun/releases/download/bun-v$version"

# The code for generating the data and source arrays below can be automatically computed based on bun version from the colab notebook at this link: https://colab.research.google.com/drive/1bicSGoDOkd7u1SeUrDjJIe2yAIR83vWu?usp=sharing

# This will store filename, arch and platform for each supported platform
data = [
    (; filename = "bun-linux-x64.zip", sha = "68a154ff1be96851b4d1a87cc5197f027ef80ab79afa3d4587150fae5c34c36e", target = "x86_64-linux-gnu", platform = Platform("x86_64", "linux"; libc = "glibc")),
    (; filename = "bun-linux-aarch64.zip", sha = "54592fd0237e3ec91a2933dff015e15a78989d97234042e7d5334a4c0ad50603", target = "aarch64-linux-gnu", platform = Platform("aarch64", "linux"; libc = "glibc")),
    (; filename = "bun-linux-x64-musl.zip", sha = "353e3a3d6fc4576592bf14a6fc3ea783a8a2811ff68e8d22f6f92fa6141c52a5", target = "x86_64-linux-musl", platform = Platform("x86_64", "linux"; libc = "musl")),
    (; filename = "bun-linux-aarch64-musl.zip", sha = "3201318206827a993e84d45d5b523a2aecd607057a623a5c12fc11e4a9b231fe", target = "aarch64-linux-musl", platform = Platform("aarch64", "linux"; libc = "musl")),
    (; filename = "bun-darwin-x64.zip", sha = "3443df70c763665db70267c6e883d312c922ccb54a085a40645e7d5603ba9b59", target = "x86_64-apple-darwin14", platform = Platform("x86_64", "macos")),
    (; filename = "bun-darwin-aarch64.zip", sha = "07895ef0fb661249b86b0b723b65b1cc4790c7f3685b63cda90122b00299972c", target = "aarch64-apple-darwin20", platform = Platform("aarch64", "macos")),
    (; filename = "bun-windows-x64.zip", sha = "e936fcfacb3cdd823f4fd60402920f52219cfe1dd970eb5650656f67a5ee9109", target = "x86_64-w64-mingw32", platform = Platform("x86_64", "windows")),
]


# Collection of sources required to complete build
# We start by putting the per-arch archive with the executable
sources = [
    [ArchiveSource("$release_url/$(d.filename)", d.sha; unpack_target = d.target) for d in data]...,
    GitSource("https://github.com/oven-sh/bun.git", "db2e7d7f748dd3951ac0c983de73e75df51bb735")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
install_license bun/LICENSE.md
install -D -m 755 -v $target/*/bun$exeext $bindir/bun$exeext
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = map(x -> x.platform, data)


# The products that we will ensure are always built
products = [
    ExecutableProduct("bun", :bun)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6"
)
