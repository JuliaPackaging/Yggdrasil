# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "wannier90"
version = v"3.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/wannier-developers/wannier90/archive/v3.1.0.tar.gz", "40651a9832eb93dec20a8360dd535262c261c34e13c41b6755fa6915c936b254")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wannier90-*/

cat > make.inc << EOF
    F90    = $FC
    FCOPTS = $FFLAGS -fPIC -O3
    LDOPTS = $LDFLAGS -fPIC
    LIBS   = -lopenblas -L${libdir}
    DYNLIBRARYEXTENSION = $dlext
EOF

make -j${nproc} wannier dynlib

# Installation in the Makefile is broken
install -d ${bindir} ${libdir}
for exe in wannier90; do
    install -m755 ${exe}.x ${bindir}/${exe}${exeext}
done
for lib in libwannier.*; do
    install -m644 $lib ${libdir}/$lib
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libwannier", :libwannier),
    ExecutableProduct("wannier90", :wannier90)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
