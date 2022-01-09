# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ADMIXTURE"
version = v"1.3.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://dalexander.github.io/admixture/binaries/admixture_linux-1.3.0.tar.gz", "353e8b170c81f8d95946bf18bc78afda5d6bd32645b2a68658bd6781ff35703c"),
    ArchiveSource("http://dalexander.github.io/admixture/binaries/admixture_macosx-1.3.0.tar.gz", "20573453d788e33c01a2756bd9200fd146adf8918b9bb4013d307055926331fc")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
echo "Not originally stated by the author, David Alexander." > LICENSE
cd ${WORKSPACE}/srcdir/
mkdir -p "${bindir}"
if [[ "${target}" == *-apple-* ]]; then     cp dist/admixture_macosx-1.3.0/admixture ${bindir}/; else     cp dist/admixture_linux-1.3.0/admixture ${bindir}/; fi
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("x86_64", "macos"; )
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("admixture", :admixture)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
