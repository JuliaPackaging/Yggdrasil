using BinaryBuilder

name = "OpenMPI"
version = v"4.0.2"
sources = [
    "https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-$(version).tar.gz" =>
    "662805870e86a1471e59739b0c34c6f9004e0c7a22db068562d5388ec4421904",
]

script = raw"""
# Enter the funzone
cd ${WORKSPACE}/srcdir/openmpi-*

./configure --prefix=$prefix --host=$target --enable-shared=yes --enable-static=no --disable-mpi-fortran --without-cs-fs

# Build the library
make "${flags[@]}" -j${nproc}

# Install the library
make "${flags[@]}" install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
#platforms = supported_platforms()
platforms = filter(p -> !isa(p, Windows), supported_platforms())

products = [
    LibraryProduct("libmpi", :libmpi)
]

dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
