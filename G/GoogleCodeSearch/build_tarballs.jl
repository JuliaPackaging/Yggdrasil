# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GoogleCodeSearch"
version = v"1.2.0"
# Adding compat bounds to the JLL of upstream v1.2.0 needed a new JLL version
ygg_version = v"1.2.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/google/codesearch.git", "8ba29bd255b740aee4eb4e4ddb5d7ec0b4d9f23e"; tag="v$(version)")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
install_license codesearch/LICENSE
cd codesearch
mkdir -pv "${bindir}"
go build -o "${bindir}/csearch${exeext}" ./cmd/csearch
go build -o "${bindir}/cindex${exeext}" ./cmd/cindex
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("csearch", :csearch),
    ExecutableProduct("cindex", :cindex)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:go, :c])
