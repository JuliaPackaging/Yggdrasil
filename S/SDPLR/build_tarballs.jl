# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SDPLR"
version = v"1.0.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://sburer.github.io/files/SDPLR-1.03-beta.zip", "f1f945734f72e008fd7be8544b27341b179292c3304226563d9c0f6cf503b2eb")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SDPLR*
make LAPACK_LIB=-lopenblas BLAS_LIB=
install -Dvm 755 "sdplr${exeext}" "${bindir}/sdplr${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("sdplr", :sdplr)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenBLAS32_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
