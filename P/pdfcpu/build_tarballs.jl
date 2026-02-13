# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "pdfcpu"
version = v"0.11.1"

sources = [
    GitSource("https://github.com/pdfcpu/pdfcpu.git", "c4b560df8f597da81cfcd21eef1ed1fefbea6a34"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pdfcpu
mkdir -p ${bindir}

# pdfcpu typically has the main command in cmd/pdfcpu
# Build the executable
go build -v -o ${bindir}/pdfcpu${exeext} ./cmd/pdfcpu
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    ExecutableProduct("pdfcpu", :pdfcpu),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:go, :c])
