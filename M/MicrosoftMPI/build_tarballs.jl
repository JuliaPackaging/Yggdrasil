using BinaryBuilder, Pkg

name = "MicrosoftMPI"
version = v"10.1.3"
sources = [
    FileSource("https://download.microsoft.com/download/a/5/2/a5207ca5-1203-491a-8fb8-906fd68ae623/msmpisetup.exe",
                  "c305ce3f05d142d519f8dd800d83a4b894fc31bcad30512cefb557feaccbe8b4"),
    FileSource("https://download.microsoft.com/download/a/5/2/a5207ca5-1203-491a-8fb8-906fd68ae623/msmpisdk.msi",
                  "f9174c54feda794586ebd83eea065be4ad38b36f32af6e7dd9158d8fd1c08433"),
    GitSource("https://github.com/eschnett/MPIconstants", "d2763908c4d69c03f77f5f9ccc546fe635d068cb"),
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

# Generate "mpi.mod", "mpi_base.mod", "mpi_sizeofs.mod" and "mpi_constants.mod"
cd $includedir
gfortran -I. ../src/mpi.f90 -fsyntax-only -fno-range-check

################################################################################
# Install MPIconstants
################################################################################

cd ${WORKSPACE}/srcdir/MPIconstants*
mkdir build
cd build

if [[ "$target" == x86_64-w64-mingw32 ]]; then
    cmake \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_FIND_ROOT_PATH=${prefix} \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DBUILD_SHARED_LIBS=ON \
        -DMPI_HOME=$prefix \
        -DMPI_GUESS_LIBRARY_NAME=MSMPI \
        -DMPI_C_LIBRARIES=msmpi64 \
        -DMPI_CXX_LIBRARIES=msmpi64 \
        ..
elif [[ "$target" == *-mingw* ]]; then
    cmake \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_FIND_ROOT_PATH=${prefix} \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DBUILD_SHARED_LIBS=ON \
        -DMPI_HOME=$prefix \
        -DMPI_GUESS_LIBRARY_NAME=MSMPI \
        ..
else
    exit 1
fi

cmake --build . --config RelWithDebInfo --parallel $nproc
cmake --build . --config RelWithDebInfo --parallel $nproc --target install

install_license $WORKSPACE/destdir/share/licenses/MicrosoftMPI/* $WORKSPACE/srcdir/MPIconstants*/LICENSE.md
"""

platforms = filter!(Sys.iswindows, supported_platforms())
platforms = expand_gfortran_versions(platforms)

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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
