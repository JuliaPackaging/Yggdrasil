using BinaryBuilder, Pkg

name = "MicrosoftMPI"
version = v"10.1.2"
sources = [
    FileSource("https://download.microsoft.com/download/a/5/2/a5207ca5-1203-491a-8fb8-906fd68ae623/msmpisetup.exe",
                  "c305ce3f05d142d519f8dd800d83a4b894fc31bcad30512cefb557feaccbe8b4"),
    FileSource("https://download.microsoft.com/download/a/5/2/a5207ca5-1203-491a-8fb8-906fd68ae623/msmpisdk.msi",
                  "d8c07fc079d35d373e14a6894288366b74147539096d43852cb0bbae32b33e44"),
    ArchiveSource("https://github.com/eschnett/MPIconstants/archive/refs/tags/v1.0.0.tar.gz",
                  "48bf7ae86c9a2dfdd9a2386ce5e0b22336c0eb381efb3e469e7ffee878b01937"),
]

script = raw"""
apk add p7zip

cd ${WORKSPACE}/srcdir/
7z x -t# msmpisetup.exe -otmp
if [[ ${target} == i686-w64-* ]]; then
    # 32-bit files
    7z x tmp/2.msi -o$prefix
else
    # 64-bit files
    7z x tmp/4.msi -o$prefix
    mv -f $prefix/msmpi64.dll $prefix/msmpi.dll
    mv -f $prefix/msmpires64.dll $prefix/msmpires.dll
fi
7z x msmpisdk.msi -o$prefix

cd ${WORKSPACE}/destdir/

chmod +x *.exe
mkdir -p bin
mv *.exe *.dll bin
mkdir -p lib
mv *.lib lib
mkdir -p include
# Move to includedir only the mpifptr.h for current architecture
mv "mpifptr${nbits}.h" "include/mpifptr.h"
rm mpifptr*.h
mv *.h *.man include
mkdir -p src
mv *.f90 src
mkdir -p share/licenses/MicrosoftMPI
mv *.txt *.rtf share/licenses/MicrosoftMPI

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

install_license LICENSE.md
"""

platforms = filter!(Sys.iswindows, supported_platforms())

products = [
    # MicrosoftMPI
    LibraryProduct("msmpi", :libmpi),
    ExecutableProduct("mpiexec", :mpiexec),
    # MPIconstants
    LibraryProduct("libload_time_mpi_constants", :libload_time_mpi_constants),
    ExecutableProduct("generate_compile_time_mpi_constants", :generate_compile_time_mpi_constants),
]

dependencies = Dependency[
]

# Build the tarballs.
# We manually bump the version up to `v10.1.3` here to avoid compat-changing issues
# X-ref: https://github.com/JuliaRegistries/General/pull/28956
version = v"10.1.3"
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
