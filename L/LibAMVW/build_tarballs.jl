# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LibAMVW"
version = v"1.0.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://people.cs.kuleuven.be/~raf.vandebril/homepage/software/AMVW.tar", "37000a9a5a83677fc18203bc6ae81657d74103b11eeb2257d3e68802731a85ae"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
FC=gfortran
LBLAS="-lopenblas"
FFLAGS="-shared -fPIC -O3"

patch doubleshift/src/DAMVW.f90 < damvw.patch
patch singleshift/src/zamvw.f90 < zamvw.patch

$FC $FFLAGS \
    doubleshift/src/DAMVW.f90 \
    doubleshift/src/DCB.f90 \
    doubleshift/src/DCDB.f90 \
    doubleshift/src/DCFD.f90 \
    doubleshift/src/DCFT.f90 \
    doubleshift/src/DFCC.f90 \
    doubleshift/src/DFGR.f90 \
    doubleshift/src/DGR.f90 \
    doubleshift/src/DMQF.f90 \
    doubleshift/src/DNORMALPOLY.f90 \
    doubleshift/src/DRANDPOLYJT.f90 \
    doubleshift/src/RESCHECK.f90 \
    doubleshift/src/balance.f90 \
    doubleshift/src/init_random_seed.f90 \
    doubleshift/src/turnovers/DGTO2.f90 \
    -o ${libdir}/libamvwdouble.${dlext} ${LBLAS}

$FC $FFLAGS \
    singleshift/src/balance.f90 \
    singleshift/src/buildbulge.f90 \
    singleshift/src/chasebulge.f90 \
    singleshift/src/cnormalpoly.f90 \
    singleshift/src/crgivens.f90 \
    singleshift/src/deflation.f90 \
    singleshift/src/diagblock.f90 \
    singleshift/src/factor.f90 \
    singleshift/src/fuse.f90 \
    singleshift/src/init_random_seed.f90 \
    singleshift/src/modified_quadratic.f90 \
    singleshift/src/normalpoly.f90 \
    singleshift/src/rescheck.f90 \
    singleshift/src/throughdiag.f90 \
    singleshift/src/zamvw.f90 \
    singleshift/src/zamvw2.f90 \
    singleshift/src/turnovers/dto4.f90 \
    -o ${libdir}/libamvwsingle.${dlext} $LBLAS
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "freebsd"),
    Platform("x86_64", "windows")
]
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libamvwdouble", :libamvwdouble)
    LibraryProduct("libamvwsingle", :libamvwsingle)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
