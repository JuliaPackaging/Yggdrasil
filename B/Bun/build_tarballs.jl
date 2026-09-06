# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Bun"
version = v"1.3.4"

release_url = "https://github.com/oven-sh/bun/releases/download/bun-v$version"

# The code for generating the data and source arrays below can be automatically computed based on bun version from the colab notebook at this link: https://colab.research.google.com/drive/1bicSGoDOkd7u1SeUrDjJIe2yAIR83vWu?usp=sharing

# This will store filename, arch and platform for each supported platform
data = [
    Platform("x86_64", "linux"; libc = "glibc") => (; filename = "bun-linux-x64.zip", sha = "33c6996049e8d37e8b815959b14b05e5b6f496121352bf11bae7d047193c28bf"),
    Platform("aarch64", "linux"; libc = "glibc") => (; filename = "bun-linux-aarch64.zip", sha = "c46e841fed85347521915b1b3904d6d175d8e2fd915e18e01c111318219115a4"),
    Platform("x86_64", "linux"; libc = "musl") => (; filename = "bun-linux-x64-musl.zip", sha = "9f1e0dd2c88b65f902a1fb101373704a67063bb7efa14b9c753f2fbd276100a3"),
    Platform("aarch64", "linux"; libc = "musl") => (; filename = "bun-linux-aarch64-musl.zip", sha = "c3dac29912b144789a2a4ee2108e595e6527f0f6c1b0f6e803bb319dc742e1de"),
    Platform("x86_64", "macos") => (; filename = "bun-darwin-x64.zip", sha = "3390f9e6a82a9c718e187513b1c56405d0de9ed3f6b092222b15b4d4ba6e304d"),
    Platform("aarch64", "macos") => (; filename = "bun-darwin-aarch64.zip", sha = "8803774e4c6c55c8a517464c508f02821e6db57f94ca1bb5cc2a39f4d2326a51"),
    Platform("x86_64", "windows") => (; filename = "bun-windows-x64.zip", sha = "2a9c0a9e6ad77d0c31fd8fb1f596b61afa7f2f2f580baad597f17e7a0dbad960"),
]

# Collection of sources required to complete build
# We start by putting the per-arch archive with the executable
sources = [
    [ArchiveSource("$release_url/$(d.filename)", d.sha; unpack_target = triplet(p)) for (p, d) in data]...,
    GitSource("https://github.com/oven-sh/bun.git", "5eb2145b3104f48eadd601518904e56aaa9937bf")
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
