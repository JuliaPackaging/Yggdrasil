using BinaryBuilder

name = "MPICH"
version = v"3.3.2"
sources = [
    ArchiveSource("https://www.mpich.org/static/downloads/$(version)/mpich-$(version).tar.gz",
                  "4bfaf8837a54771d3e4922c84071ef80ffebddbb6971a006038d91ee7ef959b9"),
    DirectorySource("./bundled"),
]

script = raw"""
# Enter the funzone
cd ${WORKSPACE}/srcdir/mpich-*

# Remove wrong libtool files
rm -f /opt/${target}/${target}/lib64/*.la
rm -f /opt/${target}/${target}/lib/*.la

atomic_patch -p1 ../patches/0001-romio-Use-tr-for-replacing-to-space-in-list-of-file-.patch
pushd src/mpi/romio
autoreconf -vi
popd

EXTRA_FLAGS=()
if [[ "${target}" != i686-linux-gnu ]] || [[ "${target}" != x86_64-linux-* ]]; then
    # Define some obscure undocumented variables needed for cross compilation of
    # the Fortran bindings.  See for example
    # * https://stackoverflow.com/q/56759636/2442087
    # * https://github.com/pmodels/mpich/blob/d10400d7a8238dc3c8464184238202ecacfb53c7/doc/installguide/cfile
    export CROSS_F77_SIZEOF_INTEGER=4
    export CROSS_F77_TRUE_VALUE=1
    export CROSS_F77_FALSE_VALUE=0

    export CROSS_F90_ADDRESS_KIND=8
    export CROSS_F90_OFFSET_KIND=8
    export CROSS_F90_INTEGER_KIND=4
    export CROSS_F90_DOUBLE_MODEL=15,307
    export CROSS_F90_REAL_MODEL=6,37

    if [[ "${target}" == i686-linux-musl ]]; then
        # Our `i686-linux-musl` platform is a bit rotten: it can run C programs,
        # but not C++ or Fortran.  `configure` runs a C program to determine
        # whether it's cross-compiling or not, but when it comes to running
        # Fortran programs, it fails.  In addition, `configure` ignores the
        # above exported variables if it believes it's doing a native build.
        # Small hack: edit `configure` script to force `cross_compiling` to be
        # always "yes".
        sed -i 's/cross_compiling=no/cross_compiling=yes/g' configure
        EXTRA_FLAGS+=(ac_cv_sizeof_bool="1")
    fi
fi

./configure --prefix=$prefix --host=$target \
    --enable-shared=yes \
    --enable-static=no \
    --disable-dependency-tracking \
    --docdir=/tmp \
    "${EXTRA_FLAGS[@]}"

# Build the library
make -j${nproc}

# Install the library
make install
"""

platforms = expand_gfortran_versions(filter!(p -> !isa(p, Windows), supported_platforms()))

products = [
    LibraryProduct("libmpi", :libmpi)
    ExecutableProduct("mpiexec", :mpiexec)
]

dependencies = Dependency[
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
