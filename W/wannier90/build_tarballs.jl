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

shared="-shared"
if [[ "${target}" == *-apple-* ]]; then
    shared="-dynamiclib"
fi
cat > make.inc << EOF
    F90    = $FC
    FCOPTS = $FFLAGS -fPIC -O2
    LDOPTS = $LDFLAGS -fPIC
    LIBS   = -lopenblas -L$prefix/lib/
    DYNLIBRARYEXTENSION = $dlext
    SHAREDLIBFLAGS      = $shared
EOF

make -j${nproc} wannier dynlib

# Installation in the Makefile is broken
install -d $prefix/bin $prefix/lib
for exe in wannier90.x; do
    install -m755 $exe $prefix/bin/$exe
done
for lib in libwannier.*; do
    install -m644 $lib $prefix/lib/$lib
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libwannier", :libwannier),
    ExecutableProduct("wannier90.x", :wannier90)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
