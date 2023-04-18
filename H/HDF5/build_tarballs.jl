# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "HDF5"
version = v"1.14.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-$(version.major).$(version.minor)/hdf5-$(version)/src/hdf5-$(version).tar.gz",
                  "a571cc83efda62e1a51a0a912dd916d01895801c5025af91669484a1575a6ef4"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir
cd hdf5-*

echo MACHTYPE: ${MACHTYPE}
echo nbits: ${nbits}
echo proc_family: ${proc_family}
echo target: ${target}

if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/H5timer.c.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/h5ls.c.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mkdir.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/strncpy.patch
fi

# HDF5 assumes that some MPI constants are C constants, but they are not
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mpi.patch

# TODO:
# - provide the registered filter plugins (BZIP2, JPEG, LZF, BLOSC, MAFISC, LZ4, Bitshuffle, and ZFP)

# Building via `configure` instead of via `cmake` has one advantage:
# The `h5cc` etc. scripts are generated, and some other packages might expect these.
if false; then

# Option 1: Build with cmake
# This is now outdated, e.g. it doesn't enable C++ nor Fortran.

# Patch `CMakeLists.txt`:
# - HDF5 would also try to build and run `H5detect` to collect ABI information.
#   We know this information, and thus can provide it manually.
# - HDF5 would try to build and run `H5make_libsettings` to collect
#   build-time information. That information seems entirely optional, so
#   we do mostly nothing instead.
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/CMakeLists.txt.patch

# Prepare the pre-generated file `H5Tinit.c` that cmake will expect:
case "${target}" in
    aarch64-apple-darwin*)
        cat ../../files/H5Tinit-darwin-arm64v8.c
        ;;
    aarch64-linux-*)
        cat ../../files/H5Tinit-debian-arm64v8.c
        ;;
    arm-linux-*)
        cat ../../files/H5Tinit-debian-arm32v7.c
        ;;
    i686-linux-*)
        cat ../../files/H5Tinit-debian-i386.c
        ;;
    i686-w64-mingw32)
        # sizeof(long double) == 12
        # layout seems to be 16-bit sign+exponent and 64-bit mantissa
        # same as for Linux
        cat ../../files/H5Tinit-debian-i386.c
        ;;
    powerpc64le-linux-*)
        cat ../../files/H5Tinit-debian-ppc64le.c
        ;;
    x86_64-apple-darwin*)
        cat ../../files/H5Tinit-darwin-amd64.c
        ;;
    x86_64-linux-* | x86_64-*-freebsd*)
        cat ../../files/H5Tinit-debian-amd64.c
        ;;
    x86_64-w64-mingw32)
        # sizeof(long double) == 16
        # layout seems to be 16-bit sign+exponent and 64-bit mantissa
        # same as for Linux
        cat ../../files/H5Tinit-debian-amd64.c 
        ;;
    *)
        echo "Unsupported target architecture ${target}" >&2
        exit 1
        ;;
esac >src/H5Tinit.c
echo 'char H5libhdf5_settings[]="";' >src/H5lib_settings.c

mkdir build
pushd build

cmake \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_STATIC_LIBS=OFF \
    -DBUILD_TESTING=OFF \
    -DHDF5_BUILD_EXAMPLES=OFF \
    -DHDF5_BUILD_HL_LIB=ON \
    -DHDF5_BUILD_TOOLS=ON \
    -DHAVE_IOEO_EXITCODE=0 \
    -DTEST_LFS_WORKS_RUN=0 \
    -DH5_LDOUBLE_TO_LONG_SPECIAL_RUN=1 \
    -DH5_LDOUBLE_TO_LONG_SPECIAL_RUN__TRYRUN_OUTPUT= \
    -DH5_LONG_TO_LDOUBLE_SPECIAL_RUN=1 \
    -DH5_LONG_TO_LDOUBLE_SPECIAL_RUN__TRYRUN_OUTPUT= \
    -DH5_LDOUBLE_TO_LLONG_ACCURATE_RUN=0 \
    -DH5_LDOUBLE_TO_LLONG_ACCURATE_RUN__TRYRUN_OUTPUT= \
    -DH5_LLONG_TO_LDOUBLE_CORRECT_RUN=0 \
    -DH5_LLONG_TO_LDOUBLE_CORRECT_RUN__TRYRUN_OUTPUT= \
    -DH5_DISABLE_SOME_LDOUBLE_CONV_RUN=1 \
    -DH5_DISABLE_SOME_LDOUBLE_CONV_RUN__TRYRUN_OUTPUT= \
    ..
cmake --build . --config RelWithDebInfo --parallel ${nproc}
cmake --build . --config RelWithDebInfo --parallel ${nproc} --target install

popd

else

# Option 2: Build with configure
# This is the currently supported way.

# Patch `configure.ac`:
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/configure.ac.patch

# Prepare the files `H5init.c` and `config.saved` that contain predetermined
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
        # same as for Linux
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
        # same as for Linux
        cp ../files/freebsd-amd64/* saved
        ;;
    x86_64-w64-mingw32)
        # sizeof(long double) == 16
        # layout seems to be 16-bit sign+exponent and 64-bit mantissa
        # same as for Linux
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

if [[ "${target}" == x86_64-linux-musl ]]; then
    # $libdir/libcurl.so needs a libnghttp, and it prefers to load /usr/lib/libnghttp2.so for this.
    # Unfortunately, that library is missing a symbol. Setting LD_LIBRARY_PATH is not enough to avoid this.
    rm /usr/lib/libcurl.*
    rm /usr/lib/libnghttp2.*
fi

FLAGS=()
if [[ "${target}" == *-mingw* ]]; then
    FLAGS+=(LDFLAGS="-no-undefined")
fi

env \
    MPITRAMPOLINE_CC="$CC" \
    MPITRAMPOLINE_CXX="$CXX" \
    MPITRAMPOLINE_FC="$FC" \
    CC=mpicc \
    CXX=mpicxx \
    FC=mpifort \
    ../configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-cxx=yes \
    --enable-direct-vfd=yes \
    --enable-fortran=yes \
    --enable-hl=yes \
    --enable-mirror-vfd=yes \
    --enable-parallel=yes \
    --enable-ros3-vfd=yes \
    --enable-static=no \
    --enable-tests=no \
    --enable-tools=yes \
    --enable-unsupported=yes \
    --with-examplesdir=/tmp \
    --with-szlib=${prefix} \
    hdf5_cv_ldouble_to_long_special=no \
    hdf5_cv_long_to_ldouble_special=no \
    hdf5_cv_ldouble_to_llong_accurate=no \
    hdf5_cv_llong_to_ldouble_correct=no \
    hdf5_cv_disable_some_ldouble_conv=yes \
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
# - HDF5 would also try to build and run `H5detect` to collect ABI information.
#   We know this information, and thus can provide it manually.
# - HDF5 would try to build and run `H5make_libsettings` to collect
#   build-time information. That information seems entirely optional, so
#   we do mostly nothing instead.
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/src-Makefile.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fortran-src-Makefile.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/hl-fortran-src-Makefile.patch

# `AM_V_P` is not defined. This must be a shell command that returns
# true or false depending on whether `make` should be verbose. This is
# probably caused by a bug in automake, or in how automake was used.
make -j${nproc} AM_V_P=: "${FLAGS[@]}"

make install

popd

fi

# # Create placeholders for missing executables
# if [[ "${target}" == *-mingw* ]]; then
#     cat >h5cc.c <<EOF
# #include <stdio.h>
# int main(int argc, char **argv) {
#   fprintf(stderr, "h5cc is not supported on this architecture\n");
#   return 1;
# }
# EOF
#     cc -c h5cc.c
#     cc -o "h5cc${exeext}" h5cc.o
#     install -Dvm 755 "h5cc${exeext}" "${bindir}/h5cc${exeext}"
# 
#     cat >h5c++.c <<EOF
# #include <stdio.h>
# int main(int argc, char **argv) {
#   fprintf(stderr, "h5c++ is not supported on this architecture\n");
#   return 1;
# }
# EOF
#     cc -c h5c++.c
#     cc -o "h5c++${exeext}" h5c++.o
#     install -Dvm 755 "h5c++${exeext}" "${bindir}/h5c++${exeext}"
# 
#     cat >h5fc.c <<EOF
# #include <stdio.h>
# int main(int argc, char **argv) {
#   fprintf(stderr, "h5fc is not supported on this architecture\n");
#   return 1;
# }
# EOF
#     cc -c h5fc.c
#     cc -o "h5fc${exeext}" h5fc.o
#     install -Dvm 755 "h5fc${exeext}" "${bindir}/h5fc${exeext}"
# 
#     cat >h5redeploy.c <<EOF
# #include <stdio.h>
# int main(int argc, char **argv) {
#   fprintf(stderr, "h5redeploy is not supported on this architecture\n");
#   return 1;
# }
# EOF
#     cc -c h5redeploy.c
#     cc -o "h5redeploy${exeext}" h5redeploy.o
#     install -Dvm 755 "h5redeploy${exeext}" "${bindir}/h5redeploy${exeext}"
# fi

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

platforms, platform_dependencies = MPI.augment_platforms(platforms)
# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

# Platforms:
#     aarch64-apple-darwin-libgfortran5-mpi+mpich
#     aarch64-apple-darwin-libgfortran5-mpi+mpitrampoline
#     aarch64-apple-darwin-libgfortran5-mpi+openmpi
#     aarch64-linux-gnu-libgfortran3-cxx03-mpi+mpich
#     aarch64-linux-gnu-libgfortran3-cxx03-mpi+mpitrampoline
#     aarch64-linux-gnu-libgfortran3-cxx03-mpi+openmpi
#     aarch64-linux-gnu-libgfortran3-cxx11-mpi+mpich
#     aarch64-linux-gnu-libgfortran3-cxx11-mpi+mpitrampoline
#     aarch64-linux-gnu-libgfortran3-cxx11-mpi+openmpi
#     aarch64-linux-gnu-libgfortran4-cxx03-mpi+mpich
#     aarch64-linux-gnu-libgfortran4-cxx03-mpi+mpitrampoline
#     aarch64-linux-gnu-libgfortran4-cxx03-mpi+openmpi
#     aarch64-linux-gnu-libgfortran4-cxx11-mpi+mpich
#     aarch64-linux-gnu-libgfortran4-cxx11-mpi+mpitrampoline
#     aarch64-linux-gnu-libgfortran4-cxx11-mpi+openmpi
#     aarch64-linux-gnu-libgfortran5-cxx03-mpi+mpich
#     aarch64-linux-gnu-libgfortran5-cxx03-mpi+mpitrampoline
#     aarch64-linux-gnu-libgfortran5-cxx03-mpi+openmpi
#     aarch64-linux-gnu-libgfortran5-cxx11-mpi+mpich
#     aarch64-linux-gnu-libgfortran5-cxx11-mpi+mpitrampoline
#     aarch64-linux-gnu-libgfortran5-cxx11-mpi+openmpi
#     aarch64-linux-musl-libgfortran3-cxx03-mpi+mpich
#     aarch64-linux-musl-libgfortran3-cxx03-mpi+openmpi
#     aarch64-linux-musl-libgfortran3-cxx11-mpi+mpich
#     aarch64-linux-musl-libgfortran3-cxx11-mpi+openmpi
#     aarch64-linux-musl-libgfortran4-cxx03-mpi+mpich
#     aarch64-linux-musl-libgfortran4-cxx03-mpi+openmpi
#     aarch64-linux-musl-libgfortran4-cxx11-mpi+mpich
#     aarch64-linux-musl-libgfortran4-cxx11-mpi+openmpi
#     aarch64-linux-musl-libgfortran5-cxx03-mpi+mpich
#     aarch64-linux-musl-libgfortran5-cxx03-mpi+openmpi
#     aarch64-linux-musl-libgfortran5-cxx11-mpi+mpich
#     aarch64-linux-musl-libgfortran5-cxx11-mpi+openmpi
#     armv6l-linux-gnueabihf-libgfortran3-cxx03-mpi+mpich
#     armv6l-linux-gnueabihf-libgfortran3-cxx03-mpi+mpitrampoline
#     armv6l-linux-gnueabihf-libgfortran3-cxx11-mpi+mpich
#     armv6l-linux-gnueabihf-libgfortran3-cxx11-mpi+mpitrampoline
#     armv6l-linux-gnueabihf-libgfortran4-cxx03-mpi+mpich
#     armv6l-linux-gnueabihf-libgfortran4-cxx03-mpi+mpitrampoline
#     armv6l-linux-gnueabihf-libgfortran4-cxx11-mpi+mpich
#     armv6l-linux-gnueabihf-libgfortran4-cxx11-mpi+mpitrampoline
#     armv6l-linux-gnueabihf-libgfortran5-cxx03-mpi+mpich
#     armv6l-linux-gnueabihf-libgfortran5-cxx03-mpi+mpitrampoline
#     armv6l-linux-gnueabihf-libgfortran5-cxx11-mpi+mpich
#     armv6l-linux-gnueabihf-libgfortran5-cxx11-mpi+mpitrampoline
#     armv6l-linux-musleabihf-libgfortran3-cxx03-mpi+mpich
#     armv6l-linux-musleabihf-libgfortran3-cxx03-mpi+openmpi
#     armv6l-linux-musleabihf-libgfortran3-cxx11-mpi+mpich
#     armv6l-linux-musleabihf-libgfortran3-cxx11-mpi+openmpi
#     armv6l-linux-musleabihf-libgfortran4-cxx03-mpi+mpich
#     armv6l-linux-musleabihf-libgfortran4-cxx03-mpi+openmpi
#     armv6l-linux-musleabihf-libgfortran4-cxx11-mpi+mpich
#     armv6l-linux-musleabihf-libgfortran4-cxx11-mpi+openmpi
#     armv6l-linux-musleabihf-libgfortran5-cxx03-mpi+mpich
#     armv6l-linux-musleabihf-libgfortran5-cxx03-mpi+openmpi
#     armv6l-linux-musleabihf-libgfortran5-cxx11-mpi+mpich
#     armv6l-linux-musleabihf-libgfortran5-cxx11-mpi+openmpi
#     armv7l-linux-gnueabihf-libgfortran3-cxx03-mpi+mpich
#     armv7l-linux-gnueabihf-libgfortran3-cxx03-mpi+mpitrampoline
#     armv7l-linux-gnueabihf-libgfortran3-cxx03-mpi+openmpi
#     armv7l-linux-gnueabihf-libgfortran3-cxx11-mpi+mpich
#     armv7l-linux-gnueabihf-libgfortran3-cxx11-mpi+mpitrampoline
#     armv7l-linux-gnueabihf-libgfortran3-cxx11-mpi+openmpi
#     armv7l-linux-gnueabihf-libgfortran4-cxx03-mpi+mpich
#     armv7l-linux-gnueabihf-libgfortran4-cxx03-mpi+mpitrampoline
#     armv7l-linux-gnueabihf-libgfortran4-cxx03-mpi+openmpi
#     armv7l-linux-gnueabihf-libgfortran4-cxx11-mpi+mpich
#     armv7l-linux-gnueabihf-libgfortran4-cxx11-mpi+mpitrampoline
#     armv7l-linux-gnueabihf-libgfortran4-cxx11-mpi+openmpi
#     armv7l-linux-gnueabihf-libgfortran5-cxx03-mpi+mpich
#     armv7l-linux-gnueabihf-libgfortran5-cxx03-mpi+mpitrampoline
#     armv7l-linux-gnueabihf-libgfortran5-cxx03-mpi+openmpi
#     armv7l-linux-gnueabihf-libgfortran5-cxx11-mpi+mpich
#     armv7l-linux-gnueabihf-libgfortran5-cxx11-mpi+mpitrampoline
#     armv7l-linux-gnueabihf-libgfortran5-cxx11-mpi+openmpi
#     armv7l-linux-musleabihf-libgfortran3-cxx03-mpi+mpich
#     armv7l-linux-musleabihf-libgfortran3-cxx03-mpi+openmpi
#     armv7l-linux-musleabihf-libgfortran3-cxx11-mpi+mpich
#     armv7l-linux-musleabihf-libgfortran3-cxx11-mpi+openmpi
#     armv7l-linux-musleabihf-libgfortran4-cxx03-mpi+mpich
#     armv7l-linux-musleabihf-libgfortran4-cxx03-mpi+openmpi
#     armv7l-linux-musleabihf-libgfortran4-cxx11-mpi+mpich
#     armv7l-linux-musleabihf-libgfortran4-cxx11-mpi+openmpi
#     armv7l-linux-musleabihf-libgfortran5-cxx03-mpi+mpich
#     armv7l-linux-musleabihf-libgfortran5-cxx03-mpi+openmpi
#     armv7l-linux-musleabihf-libgfortran5-cxx11-mpi+mpich
#     armv7l-linux-musleabihf-libgfortran5-cxx11-mpi+openmpi
#     i686-linux-gnu-libgfortran3-cxx03-mpi+mpich
#     i686-linux-gnu-libgfortran3-cxx03-mpi+mpitrampoline
#     i686-linux-gnu-libgfortran3-cxx03-mpi+openmpi
#     i686-linux-gnu-libgfortran3-cxx11-mpi+mpich
#     i686-linux-gnu-libgfortran3-cxx11-mpi+mpitrampoline
#     i686-linux-gnu-libgfortran3-cxx11-mpi+openmpi
#     i686-linux-gnu-libgfortran4-cxx03-mpi+mpich
#     i686-linux-gnu-libgfortran4-cxx03-mpi+mpitrampoline
#     i686-linux-gnu-libgfortran4-cxx03-mpi+openmpi
#     i686-linux-gnu-libgfortran4-cxx11-mpi+mpich
#     i686-linux-gnu-libgfortran4-cxx11-mpi+mpitrampoline
#     i686-linux-gnu-libgfortran4-cxx11-mpi+openmpi
#     i686-linux-gnu-libgfortran5-cxx03-mpi+mpich
#     i686-linux-gnu-libgfortran5-cxx03-mpi+mpitrampoline
#     i686-linux-gnu-libgfortran5-cxx03-mpi+openmpi
#     i686-linux-gnu-libgfortran5-cxx11-mpi+mpich
#     i686-linux-gnu-libgfortran5-cxx11-mpi+mpitrampoline
#     i686-linux-gnu-libgfortran5-cxx11-mpi+openmpi
#     i686-linux-musl-libgfortran3-cxx03-mpi+mpich
#     i686-linux-musl-libgfortran3-cxx03-mpi+openmpi
#     i686-linux-musl-libgfortran3-cxx11-mpi+mpich
#     i686-linux-musl-libgfortran3-cxx11-mpi+openmpi
#     i686-linux-musl-libgfortran4-cxx03-mpi+mpich
#     i686-linux-musl-libgfortran4-cxx03-mpi+openmpi
#     i686-linux-musl-libgfortran4-cxx11-mpi+mpich
#     i686-linux-musl-libgfortran4-cxx11-mpi+openmpi
#     i686-linux-musl-libgfortran5-cxx03-mpi+mpich
#     i686-linux-musl-libgfortran5-cxx03-mpi+openmpi
#     i686-linux-musl-libgfortran5-cxx11-mpi+mpich
#     i686-linux-musl-libgfortran5-cxx11-mpi+openmpi
#     i686-w64-mingw32-libgfortran3-cxx03-mpi+microsoftmpi
#     i686-w64-mingw32-libgfortran3-cxx11-mpi+microsoftmpi
#     i686-w64-mingw32-libgfortran4-cxx03-mpi+microsoftmpi
#     i686-w64-mingw32-libgfortran4-cxx11-mpi+microsoftmpi
#     i686-w64-mingw32-libgfortran5-cxx03-mpi+microsoftmpi
#     i686-w64-mingw32-libgfortran5-cxx11-mpi+microsoftmpi
#     powerpc64le-linux-gnu-libgfortran3-cxx03-mpi+mpich
#     powerpc64le-linux-gnu-libgfortran3-cxx03-mpi+mpitrampoline
#     powerpc64le-linux-gnu-libgfortran3-cxx03-mpi+openmpi
#     powerpc64le-linux-gnu-libgfortran3-cxx11-mpi+mpich
#     powerpc64le-linux-gnu-libgfortran3-cxx11-mpi+mpitrampoline
#     powerpc64le-linux-gnu-libgfortran3-cxx11-mpi+openmpi
#     powerpc64le-linux-gnu-libgfortran4-cxx03-mpi+mpich
#     powerpc64le-linux-gnu-libgfortran4-cxx03-mpi+mpitrampoline
#     powerpc64le-linux-gnu-libgfortran4-cxx03-mpi+openmpi
#     powerpc64le-linux-gnu-libgfortran4-cxx11-mpi+mpich
#     powerpc64le-linux-gnu-libgfortran4-cxx11-mpi+mpitrampoline
#     powerpc64le-linux-gnu-libgfortran4-cxx11-mpi+openmpi
#     powerpc64le-linux-gnu-libgfortran5-cxx03-mpi+mpich
#     powerpc64le-linux-gnu-libgfortran5-cxx03-mpi+mpitrampoline
#     powerpc64le-linux-gnu-libgfortran5-cxx03-mpi+openmpi
#     powerpc64le-linux-gnu-libgfortran5-cxx11-mpi+mpich
#     powerpc64le-linux-gnu-libgfortran5-cxx11-mpi+mpitrampoline
#     powerpc64le-linux-gnu-libgfortran5-cxx11-mpi+openmpi
#     x86_64-apple-darwin-libgfortran3-mpi+mpich
#     x86_64-apple-darwin-libgfortran3-mpi+mpitrampoline
#     x86_64-apple-darwin-libgfortran3-mpi+openmpi
#     x86_64-apple-darwin-libgfortran4-mpi+mpich
#     x86_64-apple-darwin-libgfortran4-mpi+mpitrampoline
#     x86_64-apple-darwin-libgfortran4-mpi+openmpi
#     x86_64-apple-darwin-libgfortran5-mpi+mpich
#     x86_64-apple-darwin-libgfortran5-mpi+mpitrampoline
#     x86_64-apple-darwin-libgfortran5-mpi+openmpi
#     x86_64-linux-gnu-libgfortran3-cxx03-mpi+mpich
#     x86_64-linux-gnu-libgfortran3-cxx03-mpi+mpitrampoline
#     x86_64-linux-gnu-libgfortran3-cxx03-mpi+openmpi
#     x86_64-linux-gnu-libgfortran3-cxx11-mpi+mpich
#     x86_64-linux-gnu-libgfortran3-cxx11-mpi+mpitrampoline
#     x86_64-linux-gnu-libgfortran3-cxx11-mpi+openmpi
#     x86_64-linux-gnu-libgfortran4-cxx03-mpi+mpich
#     x86_64-linux-gnu-libgfortran4-cxx03-mpi+mpitrampoline
#     x86_64-linux-gnu-libgfortran4-cxx03-mpi+openmpi
#     x86_64-linux-gnu-libgfortran4-cxx11-mpi+mpich
#     x86_64-linux-gnu-libgfortran4-cxx11-mpi+mpitrampoline
#     x86_64-linux-gnu-libgfortran4-cxx11-mpi+openmpi
#     x86_64-linux-gnu-libgfortran5-cxx03-mpi+mpich
#     x86_64-linux-gnu-libgfortran5-cxx03-mpi+mpitrampoline
#     x86_64-linux-gnu-libgfortran5-cxx03-mpi+openmpi
#     x86_64-linux-gnu-libgfortran5-cxx11-mpi+mpich
#     x86_64-linux-gnu-libgfortran5-cxx11-mpi+mpitrampoline
#     x86_64-linux-gnu-libgfortran5-cxx11-mpi+openmpi
#     x86_64-linux-musl-libgfortran3-cxx03-mpi+mpich
#     x86_64-linux-musl-libgfortran3-cxx03-mpi+openmpi
#     x86_64-linux-musl-libgfortran3-cxx11-mpi+mpich
#     x86_64-linux-musl-libgfortran3-cxx11-mpi+openmpi
#     x86_64-linux-musl-libgfortran4-cxx03-mpi+mpich
#     x86_64-linux-musl-libgfortran4-cxx03-mpi+openmpi
#     x86_64-linux-musl-libgfortran4-cxx11-mpi+mpich
#     x86_64-linux-musl-libgfortran4-cxx11-mpi+openmpi
#     x86_64-linux-musl-libgfortran5-cxx03-mpi+mpich
#     x86_64-linux-musl-libgfortran5-cxx03-mpi+openmpi
#     x86_64-linux-musl-libgfortran5-cxx11-mpi+mpich
#     x86_64-linux-musl-libgfortran5-cxx11-mpi+openmpi
#     x86_64-unknown-freebsd-libgfortran3-mpi+mpich
#     x86_64-unknown-freebsd-libgfortran3-mpi+openmpi
#     x86_64-unknown-freebsd-libgfortran4-mpi+mpich
#     x86_64-unknown-freebsd-libgfortran4-mpi+openmpi
#     x86_64-unknown-freebsd-libgfortran5-mpi+mpich
#     x86_64-unknown-freebsd-libgfortran5-mpi+openmpi
#     x86_64-w64-mingw32-libgfortran3-cxx03-mpi+microsoftmpi
#     x86_64-w64-mingw32-libgfortran3-cxx11-mpi+microsoftmpi
#     x86_64-w64-mingw32-libgfortran4-cxx03-mpi+microsoftmpi
#     x86_64-w64-mingw32-libgfortran4-cxx11-mpi+microsoftmpi
#     x86_64-w64-mingw32-libgfortran5-cxx03-mpi+microsoftmpi
#     x86_64-w64-mingw32-libgfortran5-cxx11-mpi+microsoftmpi

# The products that we will ensure are always built
products = [
    # HDF5 tools
    # ExecutableProduct("h5c++", :h5cxx),
    # ExecutableProduct("h5cc", :h5cc),
    ExecutableProduct("h5clear", :h5clear),
    ExecutableProduct("h5copy", :h5copy),
    ExecutableProduct("h5debug", :h5debug),
    ExecutableProduct("h5delete", :h5delete),
    ExecutableProduct("h5diff", :h5diff),
    ExecutableProduct("h5dump", :h5dump),
    # ExecutableProduct("h5fc", :h5fc),
    ExecutableProduct("h5format_convert", :h5format_convert),
    ExecutableProduct("h5import", :h5import),
    ExecutableProduct("h5jam",:h5jam),
    ExecutableProduct("h5ls", :h5ls),
    ExecutableProduct("h5mkgrp", :h5mkgrp),
    ExecutableProduct("h5perf_serial",:h5perf_serial),
    # ExecutableProduct("h5redeploy", :h5redeploy),
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
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD 
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else. 
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),
    Dependency("LibCURL_jll"),
    Dependency("OpenSSL_jll"; compat="1.1.10"),
    Dependency("Zlib_jll"),
    Dependency("dlfcn_win32_jll"; platforms=filter(Sys.iswindows, platforms)),
    Dependency("libaec_jll"),   # This is the successor of szlib
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
# GCC 5 reports an ICE on i686-linux-gnu-libgfortran3-cxx11-mpi+mpich
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"6")
