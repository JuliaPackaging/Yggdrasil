using BinaryBuilder, Pkg

name = "MicrosoftMPI"
microsoftmpi_version = v"10.1.3"
version = v"10.1.4"
sources = [
    FileSource("https://download.microsoft.com/download/7/2/7/72731ebb-b63c-4170-ade7-836966263a8f/msmpisetup.exe",
               "47443829114d8d8670f77af98939fe876d33eceb35d0ce4e0e85efeec4d87213"),
    FileSource("https://download.microsoft.com/download/7/2/7/72731ebb-b63c-4170-ade7-836966263a8f/msmpisdk.msi",
               "8ccbc77a0cfe1e30f7495a759886b4d99b2c494b9b9ad414dcda1da84c00d3fa"),
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
cd ${prefix}
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

# Replace an unknown character in mpif.h by a space
sed -i '/Copyright Notice/!b;n;c!    + 2002 University of Chicago' mpif.h

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

if [[ ${target} == i686-w64-* ]]; then
    # Remove 64-bit import libraries
    rm $prefix/lib/*64.lib
else
    # Rename 64-bit import libraries
    mv -f $prefix/lib/msmpifmc64.lib $prefix/lib/msmpifmc.lib
    mv -f $prefix/lib/msmpifec64.lib $prefix/lib/msmpifec.lib
    mv -f $prefix/lib/msmpi64.lib $prefix/lib/msmpi.lib
fi

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
# We use GCC 5 to ensure Fortran module files are readable by all `libgfortran3` architectures. GCC 4 would use an older format.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, preferred_gcc_version=v"5")
