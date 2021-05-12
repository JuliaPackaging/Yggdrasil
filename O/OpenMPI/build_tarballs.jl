using BinaryBuilder

name = "OpenMPI"
version = v"4.1.1"
sources = [
    ArchiveSource("https://download.open-mpi.org/release/open-mpi/v$(version.major).$(version.minor)/openmpi-$(version).tar.gz",
                  "d80b9219e80ea1f8bcfe5ad921bd9014285c4948c5965f4156a3831e60776444"),
]

script = raw"""
# Enter the funzone
cd ${WORKSPACE}/srcdir/openmpi-*

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-shared=yes --enable-static=no --disable-mpi-fortran --without-cs-fs

# Build the library
make "${flags[@]}" -j${nproc}

# Install the library
make "${flags[@]}" install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
#platforms = supported_platforms()
platforms = filter(!Sys.iswindows, supported_platforms())

products = [
    LibraryProduct("libmpi", :libmpi)
    ExecutableProduct("mpiexec", :mpiexec)
]

dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
