# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GALAHAD"
version = v"4.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ralna/GALAHAD.git", "18a4e1d2d4c9ca41072a3b83f06459992a01d7ab"),
    GitSource("https://github.com/ralna/ARCHDefs.git", "e395fe46462d74002d63e6079257b64f65f3658c")
]

# Bash recipe for building across all platforms
script = raw"""
export ARCHDEFS=$PWD/ARCHDefs
export GALAHAD=$PWD/GALAHAD

if [[ "${target}" == *-freebsd* ]] || [[ "${target}" == *-apple-* ]]; then
    CC=gcc
    CXX=g++
fi

# install_optrove requires tput
apk update
apk add ncurses

# install GALAHAD
cd ARCHDefs
printf "y1\n" > install_config
printf "nnnyn7\n" >> install_config
printf "n1\n" >> install_config
printf "n3\n" >> install_config
printf "nybn" >> install_config
./install_optrove < install_config

# copy headers in $includedir
cp $GALAHAD/include/*.h $includedir
cp $GALAHAD/objects/binarybuilder.bb.fc/double/galahad_precision.h $includedir

# generate shared libraries
cd $GALAHAD/objects/binarybuilder.bb.fc/

# We don't need these two libraries because we already have OpenBLAS32.
#
# $FC -shared -o $libdir/libgalahad_blas.$dlext -Wl,--no-undefined \
# $(flagon -Wl,--whole-archive) double/libgalahad_blas.a $(flagon -Wl,--no-whole-archive)
#
# $FC -shared -o $libdir/libgalahad_lapack.$dlext -Wl,--no-undefined \
# $(flagon -Wl,--whole-archive) double/libgalahad_lapack.a $(flagon -Wl,--no-whole-archive) \
# -L$libdir -lgalahad_blas

# We could use METIS4_jll if it provides a shared library.
$FC -shared -o $libdir/libgalahad_metis.$dlext -Wl,--no-undefined \
$(flagon -Wl,--whole-archive) double/libgalahad_metis.a $(flagon -Wl,--no-whole-archive)

$FC -shared -o $libdir/libgalahad_cutest_dummy.$dlext -Wl,--no-undefined \
$(flagon -Wl,--whole-archive) double/libgalahad_cutest_dummy.a $(flagon -Wl,--no-whole-archive)

$FC -shared -o $libdir/libgalahad_umfpack.$dlext -Wl,--no-undefined \
$(flagon -Wl,--whole-archive) double/libgalahad_umfpack.a $(flagon -Wl,--no-whole-archive)

$FC -shared -o $libdir/libgalahad_mumps.$dlext -Wl,--no-undefined \
$(flagon -Wl,--whole-archive) double/libgalahad_mumps.a $(flagon -Wl,--no-whole-archive)

$FC -shared -o $libdir/libgalahad_pastix.$dlext -Wl,--no-undefined \
$(flagon -Wl,--whole-archive) double/libgalahad_pastix.a $(flagon -Wl,--no-whole-archive)

$FC -shared -o $libdir/libgalahad_wsmp.$dlext -Wl,--no-undefined \
$(flagon -Wl,--whole-archive) double/libgalahad_wsmp.a $(flagon -Wl,--no-whole-archive)

$FC -shared -o $libdir/libgalahad_pardiso.$dlext -Wl,--no-undefined \
$(flagon -Wl,--whole-archive) double/libgalahad_pardiso.a $(flagon -Wl,--no-whole-archive)

$FC -shared -o $libdir/libgalahad_mkl_pardiso.$dlext -Wl,--no-undefined \
$(flagon -Wl,--whole-archive) double/libgalahad_mkl_pardiso.a $(flagon -Wl,--no-whole-archive)

$FC -shared -o $libdir/libgalahad_hsl.$dlext -Wl,--no-undefined \
$(flagon -Wl,--whole-archive) double/libgalahad_hsl.a $(flagon -Wl,--no-whole-archive)

$FC -shared -o $libdir/libgalahad_minpack.$dlext -Wl,--no-undefined \
$(flagon -Wl,--whole-archive) double/libgalahad_minpack.a $(flagon -Wl,--no-whole-archive)

$FC -shared -o $libdir/libgalahad_dummy.$dlext -Wl,--no-undefined \
$(flagon -Wl,--whole-archive) double/libgalahad_dummy.a $(flagon -Wl,--no-whole-archive)

$FC -shared -o $libdir/libgalahad_spral.$dlext -Wl,--no-undefined \
$(flagon -Wl,--whole-archive) double/libgalahad_spral.a $(flagon -Wl,--no-whole-archive) \
-lopenblas -lstdc++ -lgomp -lhwloc \
-L $libdir -lgalahad_metis

$FC -shared -o $libdir/libgalahad.$dlext -Wl,--no-undefined \
$(flagon -Wl,--whole-archive) double/libgalahad.a $(flagon -Wl,--no-whole-archive) \
-lopenblas -lgomp \
-L$libdir -lgalahad_cutest_dummy -lgalahad_hsl -lgalahad_hsl \
-lgalahad_metis -lgalahad_pastix \
-lgalahad_spral -lgalahad_wsmp -lgalahad_mkl_pardiso -lgalahad_pardiso

$FC -shared -o $libdir/libgalahad_hsl_c.$dlext -Wl,--no-undefined \
$(flagon -Wl,--whole-archive) double/libgalahad_hsl_c.a $(flagon -Wl,--no-whole-archive) \
-lgalahad_hsl -L./double -lgalahad_c

$FC -shared -o $libdir/libgalahad_c.$dlext -Wl,--no-undefined \
$(flagon -Wl,--whole-archive) double/libgalahad_c.a $(flagon -Wl,--no-whole-archive) \
-L$libdir -lgalahad -lgalahad_hsl_c
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libgalahad_wsmp", :libgalahad_wsmp),
    LibraryProduct("libgalahad_pastix", :libgalahad_pastix),
    LibraryProduct("libgalahad_mkl_pardiso", :libgalahad_mkl_pardiso),
    LibraryProduct("libgalahad_minpack", :libgalahad_minpack),
    LibraryProduct("libgalahad_umfpack", :libgalahad_umfpack),
    LibraryProduct("libgalahad_hsl", :libgalahad_hsl),
    LibraryProduct("libgalahad_cutest_dummy", :libgalahad_cutest_dummy),
    # LibraryProduct("libgalahad_lapack", :libgalahad_lapack),
    LibraryProduct("libgalahad_metis", :libgalahad_metis),
    LibraryProduct("libgalahad_spral", :libgalahad_spral),
    LibraryProduct("libgalahad_pardiso", :libgalahad_pardiso),
    # LibraryProduct("libgalahad_blas", :libgalahad_blas),
    LibraryProduct("libgalahad_mumps", :libgalahad_mumps),
    LibraryProduct("libgalahad_dummy", :libgalahad_dummy)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
    Dependency(PackageSpec(name="Hwloc_jll", uuid="e33a78d0-f292-5ffc-b300-72abe9b543c8"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9.1.0")
