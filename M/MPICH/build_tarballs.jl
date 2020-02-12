using BinaryBuilder

name = "MPICH"
version = v"3.3.2"
sources = [
    FileSource("https://www.mpich.org/static/downloads/$(version)/mpich-$(version).tar.gz",
               "4bfaf8837a54771d3e4922c84071ef80ffebddbb6971a006038d91ee7ef959b9"),
    DirectorySource("./bundled"),
]

script = raw"""
# Enter the funzone
cd ${WORKSPACE}/srcdir/mpich-*

atomic_patch -p1 ../patches/0001-romio-Use-tr-for-replacing-to-space-in-list-of-file-.patch
pushd src/mpi/romio
autoreconf -vi
popd

EXTRA_FLAGS=()
if [[ "${target}" == i686-linux-musl ]]; then
    # For a bug in our Musl library, we can't run C++ programs on this platform,
    # thus we need to pass a cached value for this test
    EXTRA_FLAGS+=(ac_cv_sizeof_bool="1")
fi
./configure --prefix=$prefix --host=$target \
    --enable-shared=yes \
    --enable-static=no \
    --disable-dependency-tracking \
    --disable-fortran \
    --docdir=/tmp \
    --enable-timer-type=gettimeofday \
    "${EXTRA_FLAGS[@]}"

# Build the library
make -j${nproc}

# Install the library
make install
"""

platforms = filter(p -> !isa(p, Windows), supported_platforms())

products = [
    LibraryProduct("libmpi", :libmpi)
    ExecutableProduct("mpiexec", :mpiexec)
]

dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
