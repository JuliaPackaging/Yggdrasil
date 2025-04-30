# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Bun"
version = v"1.2.11"

release_url = "https://github.com/oven-sh/bun/releases/download/bun-v$version"

# The code for generating the data and source arrays below can be automatically computed based on bun version from the colab notebook at this link: https://colab.research.google.com/drive/1bicSGoDOkd7u1SeUrDjJIe2yAIR83vWu?usp=sharing

# This will store filename, arch and platform for each supported platform
data = [
    Platform("x86_64", "linux"; libc = "glibc") => (; filename = "bun-linux-x64.zip", sha = "e481258190f8930a915ff52b5a0717b83d8f29dbd188294c9d45e37464dcf9e0"),
    Platform("aarch64", "linux"; libc = "glibc") => (; filename = "bun-linux-aarch64.zip", sha = "ac863aad053ef69d1d0f60d89ab313c61dccaaa962b2c4d7436c3efdba9595bb"),
    Platform("x86_64", "linux"; libc = "musl") => (; filename = "bun-linux-x64-musl.zip", sha = "7ae5f9e8444f8376bb6e5b868ed7293a896db67a527d1945142d171eed3c8c13"),
    Platform("aarch64", "linux"; libc = "musl") => (; filename = "bun-linux-aarch64-musl.zip", sha = "4e3d15070234b254b457918dcdf534e691643d5de570c2a1eb8c0fb9f4942329"),
    Platform("x86_64", "macos") => (; filename = "bun-darwin-x64.zip", sha = "281199c0f979ed3cdd4a543ef2afd10db03e4325c0f29f0e13e755dc011e306a"),
    Platform("aarch64", "macos") => (; filename = "bun-darwin-aarch64.zip", sha = "7d54c55c59274f2f2706481b38e6f7d90999c979f2ea522e7611bf051c5b19f4"),
    Platform("x86_64", "windows") => (; filename = "bun-windows-x64.zip", sha = "4877e62df190fd85cfd045b7b026ccc255ad692d56ee966890cf829276b54a2a"),
]

# Collection of sources required to complete build
# We start by putting the per-arch archive with the executable
sources = [
    [ArchiveSource("$release_url/$(d.filename)", d.sha; unpack_target = triplet(p)) for (p, d) in data]...,
    GitSource("https://github.com/oven-sh/bun.git", "d4b02dcdc2543cb65c4743aeac7904f380d68a8c")
]

# Bash recipe for building across all platforms
script = raw"""
unpack_target=$target
if [[ $target == *-apple-darwin* ]]; then
    # Remove whatever is after the `apple-darwin` part
    unpack_target=${target%-darwin*}-darwin
fi
cd $WORKSPACE/srcdir
install_license bun/LICENSE.md
install -D -m 755 -v $unpack_target/*/bun$exeext $bindir/bun$exeext
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = map(first, data)


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
