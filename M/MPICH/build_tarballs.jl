using BinaryBuilder

name = "MPICH"
version = v"3.3.2"
sources = [
    "https://www.mpich.org/static/downloads/$(version)/mpich-$(version).tar.gz" =>
    "4bfaf8837a54771d3e4922c84071ef80ffebddbb6971a006038d91ee7ef959b9",
]

script = raw"""
# Enter the funzone
cd ${WORKSPACE}/srcdir/mpich-*

./configure --prefix=$prefix --host=$target --enable-shared=yes --enable-static=no --disable-dependency-tracking --disable-fortran --docdir=/tmp

# Build the library
make "${flags[@]}" -j${nproc}

# Install the library
make "${flags[@]}" install
"""

# Windows and MUSL are not supported
#platforms = filter(p -> !isa(p, Windows), supported_platforms())
platforms = filter(p -> !(libc(p) == :musl), platforms)

products = [
    LibraryProduct("libmpi", :libmpi)
]

dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
