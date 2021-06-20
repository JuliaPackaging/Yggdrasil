# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "ripgrep"
version = v"13.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/BurntSushi/ripgrep/archive/$(version).tar.gz",
                  "0fb17aaf285b3eee8ddab17b833af1e190d73de317ff9648751ab0660d763ed2"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ripgrep-*/
cargo build --release --features 'pcre2'
mkdir -p "${bindir}"
cp "target/${rust_target}/release/rg${exeext}" "${bindir}/."
install_license COPYING LICENSE-MIT UNLICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("rg", :rg),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], lock_microarchitecture=false)
