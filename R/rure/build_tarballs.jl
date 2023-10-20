# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "rure"
version = v"0.2.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/rust-lang/regex.git", "061ee815ef2c44101dba7b0b124600fcb03c1912")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/regex/regex-capi/
install -Dvm 644 include/rure.h "${includedir}/rure.h"
cargo build --release
install -Dvm 755 ../target/${rust_target}/release/*rure.${dlext} "${libdir}/librure.${dlext}"
install_license LICENSE-MIT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(exclude=p->libc(p)=="musl" || p == Platform("i686", "windows"))

# The products that we will ensure are always built
products = [
    LibraryProduct("librure", :librure)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:rust, :c])
