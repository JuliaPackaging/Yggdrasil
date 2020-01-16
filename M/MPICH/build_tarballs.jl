using BinaryBuilder

name = "MPICH"
version = v"3.3.2"
sources = [
    "https://www.mpich.org/static/downloads/$(version)/mpich-$(version).tar.gz" =>
    "4bfaf8837a54771d3e4922c84071ef80ffebddbb6971a006038d91ee7ef959b9",
    "./bundled",
]

script = raw"""
# Enter the funzone
cd ${WORKSPACE}/srcdir/mpich-*

atomic_patch -p1 ../patches/0001-romio-Use-tr-for-replacing-to-space-in-list-of-file-.patch
pushd src/mpi/romio
autoreconf -vi
popd
./configure --prefix=$prefix --host=$target --enable-shared=yes --enable-static=no --disable-dependency-tracking --disable-fortran --docdir=/tmp --enable-timer-type=gettimeofday

# Build the library
make "${flags[@]}" -j${nproc}

# Install the library
make "${flags[@]}" install
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libmpi", :libmpi)
    ExecutableProduct("mpiexec", :mpiexec)
]

dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
