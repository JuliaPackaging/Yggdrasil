# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "svg2pdf"
version = v"0.10.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/typst/svg2pdf.git", "04424512b519bc0b141775b2aee1e82c68293b5b")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/svg2pdf
cargo build -p svg2pdf-cli --release
install -Dvm 755 "target/${rust_target}/release/svg2pdf${exeext}" "${bindir}/svg2pdf${exeext}"
install_license ${WORKSPACE}/srcdir/svg2pdf/LICENSE-MIT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(supported_platforms()) do p
    !(Sys.iswindows(p) && arch(p) == "i686")
end


# The products that we will ensure are always built
products = [
    ExecutableProduct("svg2pdf", :svg2pdf)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:rust, :c])
