using BinaryBuilder

name = "OpenMPI"
version = v"4.1.1"
sources = [
    ArchiveSource("https://download.open-mpi.org/release/open-mpi/v$(version.major).$(version.minor)/openmpi-$(version).tar.gz",
                  "d80b9219e80ea1f8bcfe5ad921bd9014285c4948c5965f4156a3831e60776444"),
    ArchiveSource("https://github.com/eschnett/MPIconstants/archive/refs/tags/v1.0.0.tar.gz",
                  "48bf7ae86c9a2dfdd9a2386ce5e0b22336c0eb381efb3e469e7ffee878b01937"),
    DirectorySource("./bundled"),
]

script = raw"""
################################################################################
# Install OpenMPI
################################################################################

# Enter the funzone
cd ${WORKSPACE}/srcdir/openmpi-*

if [[ "${target}" == *-freebsd* ]]; then
    # Help compiler find `complib/cl_types.h`.
    export CPPFLAGS="-I/opt/${target}/${target}/sys-root/include/infiniband"
fi

./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-shared=yes \
    --enable-static=no \
    --without-cs-fs \
    --enable-mpi-fortran=usempif08 \
    --with-cross=${WORKSPACE}/srcdir/${target}

# Build the library
make -j${nproc}

# Install the library
make install

################################################################################
# Install MPIconstants
################################################################################

cd ${WORKSPACE}/srcdir/MPIconstants*
mkdir build
cd build
# # Yes, this is tedious. No, without being this explicit, cmake will
# # not properly auto-detect the MPI libraries.
# if [ -f ${prefix}/lib/libpmpi.${dlext} ]; then
#     cmake \
#         -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
#         -DCMAKE_FIND_ROOT_PATH=${prefix} \
#         -DCMAKE_INSTALL_PREFIX=${prefix} \
#         -DBUILD_SHARED_LIBS=ON \
#         -DMPI_C_COMPILER=cc \
#         -DMPI_C_LIB_NAMES='mpi;pmpi' \
#         -DMPI_mpi_LIBRARY=${prefix}/lib/libmpi.${dlext} \
#         -DMPI_pmpi_LIBRARY=${prefix}/lib/libpmpi.${dlext} \
#         ..
# else
#     cmake \
#         -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
#         -DCMAKE_FIND_ROOT_PATH=${prefix} \
#         -DCMAKE_INSTALL_PREFIX=${prefix} \
#         -DBUILD_SHARED_LIBS=ON \
#         -DMPI_C_COMPILER=cc \
#         -DMPI_C_LIB_NAMES='mpi' \
#         -DMPI_mpi_LIBRARY=${prefix}/lib/libmpi.${dlext} \
#         ..
# fi

cmake \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DBUILD_SHARED_LIBS=ON \
    ..

cmake --build . --config RelWithDebInfo --parallel $nproc
cmake --build . --config RelWithDebInfo --parallel $nproc --target install

################################################################################
# Install licenses
################################################################################

install_license $WORKSPACE/srcdir/openmpi*/LICENSE $WORKSPACE/srcdir/MPIconstants-*/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
#platforms = supported_platforms()
platforms = filter(p -> !Sys.iswindows(p) && !(arch(p) == "armv6l" && libc(p) == "glibc"), supported_platforms(; experimental=true))
platforms = expand_gfortran_versions(platforms)
    
products = [
    # OpenMPI
    LibraryProduct("libmpi", :libmpi),
    ExecutableProduct("mpiexec", :mpiexec),
    # MPIconstants
    LibraryProduct("libload_time_mpi_constants", :libload_time_mpi_constants),
    ExecutableProduct("generate_compile_time_mpi_constants", :generate_compile_time_mpi_constants),
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
