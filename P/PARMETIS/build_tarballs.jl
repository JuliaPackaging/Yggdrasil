using BinaryBuilder

name = "PARMETIS"
version = v"4.0.3"

# Collection of sources required to build PARMETIS.
# The patch prevents building the source of METIS that ships with PARMETIS;
# we rely on METIS_jll instead.
sources = [
    ArchiveSource("http://glaros.dtc.umn.edu/gkhome/fetch/sw/parmetis/parmetis-4.0.3.tar.gz",
                  "f2d9a231b7cf97f1fee6e8c9663113ebf6c240d407d3c118c55b3633d6be6e5f"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${libdir}
cd $WORKSPACE/srcdir/parmetis-4.0.3

for f in ${WORKSPACE}/srcdir/patches/*.patch; do
  atomic_patch -p1 ${f}
done

cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DSHARED=1 \
    -DGKLIB_PATH=$(realpath ../metis/GKlib) \
    -DMETIS_PATH=$(realpath ../metis) \
    -DMPI_INCLUDE_PATH="${prefix}/include" \
    -DMPI_LIBRARIES="mpi"
make -j${nproc}
make install
"""

# OpenMPI and MPICH are not precompiled for Windows
platforms = filter!(!Sys.iswindows, supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libparmetis", :libparmetis)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("METIS_jll"),
    Dependency("MPICH_jll")
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
