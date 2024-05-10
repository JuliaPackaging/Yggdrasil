# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "minimap2"
version = v"2.28.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lh3/minimap2.git", "8170693de39b667d11c8931d343c94a23a7690d2"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd minimap2
if [[ ${target} == x86_64* ]]; then
    make
else
    make arm_neon=1 aarch64=1
fi
install -Dvm 755 minimap2 "${bindir}/minimap2${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("aarch64", "macos"; ),
    Platform("x86_64", "windows"; ),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("x86_64", "macos"; ),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("x86_64", "freebsd"; ),
    Platform("aarch64", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("minimap2", :minimap2)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
