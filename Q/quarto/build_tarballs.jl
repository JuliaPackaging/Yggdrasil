# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "quarto"
version = v"1.1.29"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/quarto-dev/quarto-cli.git", "6a42361a388433ad8b52ab71759a50e778b48ba0"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/quarto-cli
source configuration
export QUARTO_BIN_DIR=/workspace/destdir/bin
/workspace/destdir/bin/deno run --unstable --allow-env --allow-read --allow-write --allow-run --allow-net --allow-ffi --importmap=/workspace/srcdir/quarto-cli/src/dev_import_map.json /workspace/srcdir/quarto-cli/package/src/bld.ts $@
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
    ExecutableProduct("quarto", :quarto)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Deno_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
