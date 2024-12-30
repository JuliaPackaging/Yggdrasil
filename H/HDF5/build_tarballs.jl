# Note that this script can accept some limited command-line arguments,
# run `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "HDF5"
version = v"1.14.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-$(version.major).$(version.minor)/hdf5-$(version)/src/hdf5-$(version).tar.bz2",
                  "9425f224ed75d1280bb46d6f26923dd938f9040e7eaebf57e66ec7357c08f917"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/hdf5-*

if [[ ${target} == *-mingw* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/h5ls.c.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mkdir.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/strncpy.patch
    cp ${WORKSPACE}/srcdir/headers/pthread_time.h "/opt/${target}/${target}/sys-root/include/pthread_time.h"
fi

# HDF5 assumes that some MPI constants are C constants, but they are not
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mpi.patch

# Patch `configure.ac`:
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/configure.ac.patch

# Prepare the file `config.saved` that contains predetermined
# configuration information
mkdir saved
case "${target}" in
    aarch64-apple-darwin*)
        cp ../files/darwin-arm64v8/* saved
        ;;
    aarch64-linux-*)
        cp ../files/debian-arm64v8/* saved
        ;;
    arm-linux-*)
        cp ../files/debian-arm32v7/* saved
        ;;
    i686-linux-*)
        cp ../files/debian-i386/* saved
        ;;
    i686-w64-mingw32)
        # sizeof(long double) == 12
        # layout seems to be 16-bit sign+exponent and 64-bit mantissa
        cp ../files/msys2-mingw32/* saved
        ;;
    powerpc64le-linux-*)
        cp ../files/debian-ppc64le/* saved
        ;;
    x86_64-apple-darwin*)
        cp ../files/darwin-amd64/* saved
        ;;
    x86_64-linux-*)
        cp ../files/debian-amd64/* saved
        ;;
    x86_64-*-freebsd*)
        # no __float128
        cp ../files/freebsd-amd64/* saved
        ;;
    x86_64-w64-mingw32)
        # sizeof(long double) == 16
        # layout seems to be 16-bit sign+exponent and 64-bit mantissa
        cp ../files/msys2-mingw64/* saved
        ;;
    *)
        echo "Unsupported target architecture ${target}" >&2
        exit 1
        ;;
esac
cp ../files/get_config_setting saved

env \
    HDF5_ACLOCAL=/usr/bin/aclocal \
    HDF5_AUTOHEADER=/usr/bin/autoheader \
    HDF5_AUTOMAKE=/usr/bin/automake \
    HDF5_AUTOCONF=/usr/bin/autoconf \
    HDF5_LIBTOOL=/usr/bin/libtool \
    HDF5_M4=/usr/bin/m4 \
    ./autogen.sh

mkdir build
pushd build

# Required for x86_64-linux-musl:
# - Some HDF5 C code requires C99, but configure only requests C89.
# - Some HDF5 C++ code requires C++11, but configure does not request this.
# This might not be necessary if we switch to newer GCC versions.
export CFLAGS="${CFLAGS} -std=c99"
export CXXFLAGS="${CXXFLAGS} -std=c++11"

if [[ ${target} == x86_64-linux-musl ]]; then
    # ${libdir}/libcurl.so needs a libnghttp, and it prefers to load /usr/lib/libnghttp2.so for this.
    # Unfortunately, that library is missing a symbol. Setting LD_LIBRARY_PATH is not enough to avoid this.
    rm /usr/lib/libcurl.*
    rm /usr/lib/libnghttp2.*
fi

FLAGS=()
if [[ ${target} == *-mingw* ]]; then
    FLAGS+=(LDFLAGS='-no-undefined')
    # For OpenSSL's libcrypto for ROS3-VFD
    export CFLAGS="${CFLAGS} -L${prefix}/lib64"
    export FCFLAGS="${FCFLAGS} -L${prefix}/lib64"
fi

# Check which VFD are available
ENABLE_DIRECT_VFD=yes
ENABLE_MIRROR_VFD=yes
if [[ ${target} == *-darwin* ]]; then
    ENABLE_DIRECT_VFD=no
elif [[ ${target} == *-w64-mingw32 ]]; then
    ENABLE_DIRECT_VFD=no
    ENABLE_MIRROR_VFD=no
fi

# Configure MPI
if grep -q MSMPI_VER ${prefix}/include/mpi.h; then
    # Microsoft MPI
    if [[ ${target} == i686-* ]]; then
        # 32-bit system
        # Do not enable MPI; the function MPI_File_close is not defined
        # in the 32-bit version of Microsoft MPI 10.1.12498.18
        :
    elif false; then
        # DISABLED
        # 64-bit system
        # Do not enable MPI
        # Mingw-w64 runtime failure:
        # 32 bit pseudo relocation at 0000000007828E2C out of range, targeting 00007FFDE78BAD90, yielding the value 00007FFDE0091F60.
        # Consider: https://www.symscape.com/configure-msmpi-for-mingw-w64
        # gendef msmpi.dll - creates msmpi.def
        # x86_64-w64-mingw32-dlltool -d msmpi.def -l libmsmpi.a -D msmpi.dll - creates libmsmpi.a

        # Hide static libraries
        rm ${prefix}/lib/msmpi*.lib
        # Make shared libraries visible
        ln -s msmpi.dll ${libdir}/libmsmpi.dll
        ENABLE_PARALLEL=yes
        export FCFLAGS="${FCFLAGS} -I${prefix}/src -I${prefix}/include -fno-range-check"
        export LIBS="-L${libdir} -lmsmpi"
    fi
else
    ENABLE_PARALLEL=yes
    export MPITRAMPOLINE_CC="${CC}"
    export MPITRAMPOLINE_CXX="${CXX}"
    export MPITRAMPOLINE_FC="${FC}"
    export CC=mpicc
    export CXX=mpicxx
    export FC=mpifort
fi

# This is a bug in HDF5; see
# <https://github.com/HDFGroup/hdf5/issues/3925>. The file
# `config/freebsd` includes `config/classic-fflags` which is
# missing.
: >../config/classic-fflags

../configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-cxx=yes \
    --enable-direct-vfd="$ENABLE_DIRECT_VFD" \
    --enable-fortran=yes \
    --enable-hl=yes \
    --enable-mirror-vfd="$ENABLE_MIRROR_VFD" \
    --enable-parallel="$ENABLE_PARALLEL" \
    --enable-ros3-vfd=yes \
    --enable-static=no \
    --enable-tests=no \
    --enable-tools=yes \
    --enable-unsupported=yes \
    --with-examplesdir=/tmp \
    --with-szlib=${prefix} \
    hdf5_cv_ldouble_to_long_special=no \
    hdf5_cv_long_to_ldouble_special=no \
    hdf5_cv_ldouble_to_llong_accurate=yes \
    hdf5_cv_llong_to_ldouble_correct=yes \
    hdf5_cv_disable_some_ldouble_conv=no \
    hdf5_cv_szlib_can_encode=yes \
    "$(../saved/get_config_setting PAC_C_MAX_REAL_PRECISION ../saved/config.status)" \
    "$(../saved/get_config_setting PAC_FC_ALL_REAL_KINDS ../saved/config.status)" \
    "$(../saved/get_config_setting PAC_FC_MAX_REAL_PRECISION ../saved/config.status)" \
    "$(../saved/get_config_setting PAC_FORTRAN_NUM_INTEGER_KINDS ../saved/config.status)" \
    "$(../saved/get_config_setting PAC_FC_ALL_INTEGER_KINDS ../saved/config.status)" \
    "$(../saved/get_config_setting PAC_FC_ALL_REAL_KINDS_SIZEOF ../saved/config.status)" \
    "$(../saved/get_config_setting PAC_FC_ALL_INTEGER_KINDS_SIZEOF ../saved/config.status)" \
    "$(../saved/get_config_setting PAC_FORTRAN_NATIVE_INTEGER_KIND ../saved/config.status)" \
    "$(../saved/get_config_setting PAC_FORTRAN_NATIVE_INTEGER_SIZEOF ../saved/config.status)" \
    "$(../saved/get_config_setting PAC_FORTRAN_NATIVE_REAL_KIND ../saved/config.status)" \
    "$(../saved/get_config_setting PAC_FORTRAN_NATIVE_REAL_SIZEOF ../saved/config.status)" \
    "$(../saved/get_config_setting PAC_FORTRAN_NATIVE_DOUBLE_KIND ../saved/config.status)" \
    "$(../saved/get_config_setting PAC_FORTRAN_NATIVE_DOUBLE_SIZEOF ../saved/config.status)" \
    "$(../saved/get_config_setting HAVE_Fortran_INTEGER_SIZEOF ../saved/config.status)" \
    "$(../saved/get_config_setting FORTRAN_HAVE_C_LONG_DOUBLE ../saved/config.status)" \
    "$(../saved/get_config_setting FORTRAN_C_LONG_DOUBLE_IS_UNIQUE ../saved/config.status)" \
    "$(../saved/get_config_setting H5CONFIG_F_NUM_RKIND ../saved/config.status)" \
    "$(../saved/get_config_setting H5CONFIG_F_RKIND ../saved/config.status)" \
    "$(../saved/get_config_setting H5CONFIG_F_RKIND_SIZEOF ../saved/config.status)" \
    "$(../saved/get_config_setting H5CONFIG_F_NUM_IKIND ../saved/config.status)" \
    "$(../saved/get_config_setting H5CONFIG_F_IKIND ../saved/config.status)"

# Patch the generated `Makefile`:
# (We could instead patch `Makefile.in`, or maybe even `Makefile.am`.)
# HDF5 would otherwise try to build and run code to determine what
# integer and real types are available in Fortran. This doesn't work
# while cross-compiling. We thus provide pre-recorded information
# instead (see `config.saved` above).
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fortran-src-Makefile.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/hl-fortran-src-Makefile.patch

# `AM_V_P` is not defined. This must be a shell command that returns
# true or false depending on whether `make` should be verbose. This is
# probably caused by a bug in automake, or in how automake was used.
make -j${nproc} AM_V_P=: "${FLAGS[@]}"

make install

popd

install_license COPYING
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.5.0", OpenMPI_compat="4.1.6, 5")
# TODO: Use MPI only on non-Windows platforms
# platforms = [filter(!Sys.iswindows, mpi_platforms); filter(Sys.iswindows, platforms)]

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)

# The products that we will ensure are always built
products = [
    # # HDF5 tools
    ExecutableProduct("h5clear", :h5clear),
    ExecutableProduct("h5copy", :h5copy),
    ExecutableProduct("h5debug", :h5debug),
    ExecutableProduct("h5delete", :h5delete),
    ExecutableProduct("h5diff", :h5diff),
    ExecutableProduct("h5dump", :h5dump),
    ExecutableProduct("h5format_convert", :h5format_convert),
    ExecutableProduct("h5import", :h5import),
    ExecutableProduct("h5jam",:h5jam),
    ExecutableProduct("h5ls", :h5ls),
    ExecutableProduct("h5mkgrp", :h5mkgrp),
    ExecutableProduct("h5perf_serial",:h5perf_serial),
    ExecutableProduct("h5repack", :h5repack),
    ExecutableProduct("h5repart", :h5repart),
    ExecutableProduct("h5stat", :h5stat),
    ExecutableProduct("h5unjam", :h5unjam),
    ExecutableProduct("h5watch", :h5watch),

    # HDF5 libraries
    LibraryProduct("libhdf5", :libhdf5),
    LibraryProduct("libhdf5_cpp", :libhdf5_cpp),
    LibraryProduct("libhdf5_fortran", :libhdf5_fortran),
    LibraryProduct("libhdf5_hl", :libhdf5_hl),
    LibraryProduct("libhdf5_hl_cpp", :libhdf5_hl_cpp),
    LibraryProduct("libhdf5hl_fortran", :libhdf5_hl_fortran),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # To ensure that the correct version of libgfortran is found at runtime
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("LibCURL_jll"; compat="7.73,8"),
    Dependency("OpenSSL_jll"; compat="3.0.8"),
    Dependency("Zlib_jll"),
    # Dependency("dlfcn_win32_jll"; platforms=filter(Sys.iswindows, platforms)),
    Dependency("libaec_jll"),   # This is the successor of szlib
]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and `dlopen`s the shared libraries.
# (MPItrampoline will skip its automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# Build the tarballs, and possibly a `build.jl` as well.
# GCC 5 reports an ICE on i686-linux-gnu-libgfortran3-cxx11-mpi+mpich
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"6")

# Trigger build: 1
