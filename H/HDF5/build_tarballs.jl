# Note that this script can accept some limited command-line arguments,
# run `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "HDF5"
version = v"1.14.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-$(version.major).$(version.minor)/hdf5-$(version)/src/hdf5-$(version).tar.bz2",
                  "ea3c5e257ef322af5e77fc1e52ead3ad6bf3bb4ac06480dd17ee3900d7a24cfb"),
    DirectorySource("./bundled"),

    # We don't build HDF5 on Windows; instead, we use packages from msys there:

    # 32-bit Windows from https://packages.msys2.org/package/mingw-w64-i686-hdf5
    ArchiveSource("https://mirror.msys2.org/mingw/mingw32/mingw-w64-i686-hdf5-1.14.2-2-any.pkg.tar.zst",
                  "ab053fdafb3e0c456751fed9fe5cc2fa339042046b4de677ce2848cd8b6d3b3f"; unpack_target="i686-w64-mingw32"),
    ArchiveSource("https://mirror.msys2.org/mingw/mingw32/mingw-w64-i686-zlib-1.3-1-any.pkg.tar.zst",
                  "21bacf3a43073749a4cbdf407c7f1da92bab56c80925b1205f7c4cb289c724a1"; unpack_target="i686-w64-mingw32"),
    # We need some special compiler support libraries from mingw for i686 (libgcc_s_dw2)
    ArchiveSource("https://mirror.msys2.org/mingw/mingw32/mingw-w64-i686-gcc-libs-13.2.0-2-any.pkg.tar.zst",
                  "2dae8189318a91067cca895572b2b46183bfd2ee97a55127a84f4f418f0b32f3"; unpack_target="i686-w64-mingw32"),

    # 64-bit Windows from https://packages.msys2.org/package/mingw-w64-x86_64-hdf5
    ArchiveSource("https://mirror.msys2.org/mingw/mingw64/mingw-w64-x86_64-hdf5-1.14.2-2-any.pkg.tar.zst",
                  "19a0a28d32c8990a29e001b77fe2deeb4946ff6c7d0949dbf756dfe1b9b40e8a"; unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("https://mirror.msys2.org/mingw/mingw64/mingw-w64-x86_64-zlib-1.3-1-any.pkg.tar.zst",
                  "254a6c5a8a27d1b787377a3e70a39cceb200b47c5f15f4ab5bfa1431b718ef98"; unpack_target="x86_64-w64-mingw32"),

]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir

# We don't build HDF5 on Windows; instead, we use packages from msys there:
if [[ ${target} == *mingw* ]]; then
    cd ${target}/mingw${nbits}

    mkdir -p ${libdir} ${includedir}
    rm -f lib/{*_cpp*,*fortran*,*f90*} # we do not need these
    rm -f bin/{*_cpp*,*fortran*,*f90*} # we do not need these
    
    mv -v lib/libhdf5*.dll.a ${prefix}/lib
    mv -v bin/*.dll ${libdir}
    mv -v include/* ${includedir}

    install_license share/doc/hdf5/COPYING
    exit 0
fi

cd hdf5-*

if [[ ${target} == *-mingw* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/h5ls.c.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mkdir.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/strncpy.patch
    cp ${WORKSPACE}/srcdir/headers/pthread_time.h "/opt/${target}/${target}/sys-root/include/pthread_time.h"
fi

# HDF5 assumes that some MPI constants are C constants, but they are not
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mpi.patch

# Idea:
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

if [[ ${target} == x86_64-linux-musl ]]; then
    # ${libdir}/libcurl.so needs a libnghttp, and it prefers to load /usr/lib/libnghttp2.so for this.
    # Unfortunately, that library is missing a symbol. Setting LD_LIBRARY_PATH is not enough to avoid this.
    rm /usr/lib/libcurl.*
    rm /usr/lib/libnghttp2.*
fi

FLAGS=()
if [[ ${target} == *-mingw* ]]; then
    FLAGS+=(LDFLAGS='-no-undefined')
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
ENABLE_PARALLEL=yes
if grep -q MPICH_NAME ${prefix}/include/mpi.h; then
    # MPICH
    export CC=mpicc
    export CXX=mpicxx
    export FC=mpifort
elif grep -q MPITRAMPOLINE_MPI_H ${prefix}/include/mpi.h; then
    # MPItrampoline
    export MPITRAMPOLINE_CC="$(which $CC)"
    export MPITRAMPOLINE_CXX="$(which $CXX)"
    export MPITRAMPOLINE_FC="$(which $FC)"
    export CC=mpicc
    export CXX=mpicxx
    export FC=mpifort
elif grep -q MSMPI_VER ${prefix}/include/mpi.h; then
    # Microsoft MPI
    if [[ ${target} == i686-* ]]; then
        # 32-bit system
        # Do not enable MPI; the function MPI_File_close is not defined
        # in the 32-bit version of Microsoft MPI 10.1.12498.18
        ENABLE_PARALLEL=no
    else
        # Hide static libraries
        rm ${prefix}/lib/msmpi*.lib
        # Make shared libraries visible
        ln -s msmpi.dll ${libdir}/libmsmpi.dll
        export FCFLAGS="$FCFLAGS -I${prefix}/src -I${prefix}/include -fno-range-check"
        export LIBS="-L${libdir} -lmsmpi"
    fi
elif grep -q OMPI_MAJOR_VERSION ${prefix}/include/mpi.h; then
    # OpenMPI
    export CC=mpicc
    export CXX=mpicxx
    export FC=mpifort
else
    # Unknown MPI
    exit 1
fi

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
# TODO: Don't expand ABIs for Windows since we're not providing either C++ or Fortran bindings there.
platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)

# TODO: Don't require MPI for Windows since we're using the non-MPI msys libraries there.
platforms, platform_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.3.0")

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

# The products that we will ensure are always built
products = [
    # Since we use the msys binaries for Windows, we can only define
    # those products that are provided by msys as well. These are
    # just the regular and the high-level libraries.

    # # HDF5 tools
    # ExecutableProduct("h5clear", :h5clear),
    # ExecutableProduct("h5copy", :h5copy),
    # ExecutableProduct("h5debug", :h5debug),
    # ExecutableProduct("h5delete", :h5delete),
    # ExecutableProduct("h5diff", :h5diff),
    # ExecutableProduct("h5dump", :h5dump),
    # ExecutableProduct("h5format_convert", :h5format_convert),
    # ExecutableProduct("h5import", :h5import),
    # ExecutableProduct("h5jam",:h5jam),
    # ExecutableProduct("h5ls", :h5ls),
    # ExecutableProduct("h5mkgrp", :h5mkgrp),
    # ExecutableProduct("h5perf_serial",:h5perf_serial),
    # ExecutableProduct("h5repack", :h5repack),
    # ExecutableProduct("h5repart", :h5repart),
    # ExecutableProduct("h5stat", :h5stat),
    # ExecutableProduct("h5unjam", :h5unjam),
    # ExecutableProduct("h5watch", :h5watch),

    # HDF5 libraries
    LibraryProduct("libhdf5", :libhdf5),
    # LibraryProduct("libhdf5_cpp", :libhdf5_cpp),
    # LibraryProduct("libhdf5_fortran", :libhdf5_fortran),
    LibraryProduct("libhdf5_hl", :libhdf5_hl),
    # LibraryProduct("libhdf5_hl_cpp", :libhdf5_hl_cpp),
    # LibraryProduct("libhdf5hl_fortran", :libhdf5_hl_fortran),
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
    # The msys Windows libraries require OpenSSL@3
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
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"6")
