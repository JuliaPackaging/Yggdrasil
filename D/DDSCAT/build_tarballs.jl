# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "DDSCAT"
version = v"7.3.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://ddscat.wikidot.com/local--files/downloads/ddscat$(version)_220120.tgz", "06f2673a45fcff20b8ed9f37d5bedeb84604d7a9fb10f627096833163769d1e7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/src
make ddscat
mv ddscat "ddscat${exeext}" || true
install -Dvm 755 "ddscat${exeext}" "${bindir}/ddscat${exeext}"
install_license ../doc/UserGuide.pdf
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(filter(x->arch(x) != "powerpc64le", supported_platforms()))


# The products that we will ensure are always built
products = [
    ExecutableProduct("ddscat", :ddscat)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
