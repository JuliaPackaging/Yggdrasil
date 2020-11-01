# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "AlgRemez"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/maddyscientist/AlgRemez.git", "bdacfd1b9a7f5c34275da5f3a5a3f7f8cbbf8d9c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd AlgRemez/src/
mkdir -p ${bindir}
make INCLIST=-I${includedir} LDFLAGS="-L${libdir} -lmpfr -lgmp" BIN=${bindir}/algremez${exeext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("algremez", :algremez)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.1.2"),
    Dependency(PackageSpec(name="MPFR_jll", uuid="3a97d323-0669-5f0c-9066-3539efd106a3"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
