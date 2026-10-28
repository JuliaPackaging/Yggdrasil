using BinaryBuilder, Pkg

name = "MicrosoftMPI"
version = v"10.1.3"
# JLL v10.1.3 holds an earlier MS-MPI release, and v10.1.5 raised julia_compat to 1.6
ygg_version = v"10.1.5"
sources = [
    FileSource("https://download.microsoft.com/download/7/2/7/72731ebb-b63c-4170-ade7-836966263a8f/msmpisetup.exe",
               "47443829114d8d8670f77af98939fe876d33eceb35d0ce4e0e85efeec4d87213"),
    FileSource("https://download.microsoft.com/download/7/2/7/72731ebb-b63c-4170-ade7-836966263a8f/msmpisdk.msi",
               "8ccbc77a0cfe1e30f7495a759886b4d99b2c494b9b9ad414dcda1da84c00d3fa"),
    GitSource("https://github.com/eschnett/MPIconstants", "d2763908c4d69c03f77f5f9ccc546fe635d068cb"),
]

script = raw"""
apk del cmake
apk add p7zip

cd ${WORKSPACE}/srcdir
7z x -t# msmpisetup.exe -osetup
7z x msmpisdk.msi -osdk
# The 64-bit MSI and SDK ship both architectures, with the 64-bit files suffixed "64"
if [[ ${nbits} == 32 ]]; then
    7z x setup/2.msi -oruntime
    suffix=""
    # The stdcall Fortran import libraries only exist for 32-bit
    import_libs="msmpi msmpifec msmpifes msmpifmc msmpifms"
else
    7z x setup/4.msi -oruntime
    suffix="64"
    import_libs="msmpi msmpifec msmpifmc"
fi

install -Dvm 755 runtime/*.exe -t ${bindir}
install -Dvm 755 runtime/msmpi${suffix}.dll ${libdir}/msmpi.dll
install -Dvm 755 runtime/msmpires${suffix}.dll ${libdir}/msmpires.dll
for lib in ${import_libs}; do
    install -Dvm 644 sdk/${lib}${suffix}.lib ${prefix}/lib/${lib}.lib
done

# Replace a raw Latin-1 byte in mpif.h by a space. Not a patch: the file is CRLF,
# and .gitattributes would convert a patch's context lines to LF.
sed -i '/Copyright Notice/!b;n;c!    + 2002 University of Chicago' sdk/mpif.h
install -Dvm 644 sdk/mpi.h sdk/mpio.h sdk/mpif.h sdk/mspms.h sdk/pmidbg.h runtime/mpitrace.man -t ${includedir}
install -Dvm 644 sdk/mpifptr${nbits}.h ${includedir}/mpifptr.h
install -Dvm 644 sdk/mpi.f90 -t ${prefix}/src

# Generate "mpi.mod", "mpi_base.mod", "mpi_sizeofs.mod" and "mpi_constants.mod"
cd ${includedir}
${FC} -I. ../src/mpi.f90 -fsyntax-only -fno-range-check

################################################################################
# Install MPIconstants
################################################################################

cd ${WORKSPACE}/srcdir/MPIconstants*
cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DBUILD_SHARED_LIBS=ON \
    -DMPI_HOME=${prefix} \
    -DMPI_GUESS_LIBRARY_NAME=MSMPI
cmake --build build --parallel ${nproc}
cmake --install build

install_license \
    ${WORKSPACE}/srcdir/runtime/*.rtf \
    ${WORKSPACE}/srcdir/runtime/*.txt \
    ${WORKSPACE}/srcdir/sdk/*.rtf \
    ${WORKSPACE}/srcdir/sdk/*.txt \
    ${WORKSPACE}/srcdir/MPIconstants*/LICENSE.md
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

dependencies = [
    HostBuildDependency("CMake_jll"),
]

# Build the tarballs.
# We use GCC 5 to ensure Fortran module files are readable by all `libgfortran3` architectures. GCC 4 would use an older format.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
