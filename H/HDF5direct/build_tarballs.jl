# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "HDF5"
version = v"1.14.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.14/hdf5-1.14.0/src/hdf5-1.14.0.tar.gz",
                  "a571cc83efda62e1a51a0a912dd916d01895801c5025af91669484a1575a6ef4"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir
cd hdf5-*

mkdir build
cd build

mkdir config-tests
pushd config-tests

cat >test.c <<EOF
int size = sizeof(long double);
EOF
cc -S test.c
SIZEOF_LONG_DOUBLE=$(grep '.long' test.s | sed -e 's/^	\.long	\(\d*\)$/\1/')

cat >test.c <<EOF
int size = sizeof(long);
EOF
cc -S test.c
SIZEOF_LONG=$(grep '.long' test.s | sed -e 's/^	\.long	\(\d*\)$/\1/')

popd

# TODO:
# - understand and fix long double / long configure tests
# - -DHDF5_ENABLE_HDFS=ON
# - -DHDF5_ENABLE_PARALLEL=ON
# - -DDEFAULT_API_VERSION=...
# - -DHDF5_ENABLE_THREADSAFE=ON
# - build C++ and Fortran support
# - -DHDF5_ENABLE_MAP_API=ON
# - -DHDF5_BUILD_PARALLEL_TOOLS=ON
# - correct floating-point descriptors for non-x86_64 architectures
# - check floating-point descriptors for non-linux x86_64 architectures

# cmake aborts because it cannot write some files
# cmake \
#     -DCMAKE_FIND_ROOT_PATH=${prefix} \
#     -DCMAKE_INSTALL_PREFIX=${prefix} \
#     -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
#     -DBUILD_STATIC_LIBS=OFF \
#     -DHDF5_BUILD_EXAMPLES=OFF \
#     -DTEST_LFS_WORKS_RUN=0 \
#     -DH5_LDOUBLE_TO_LONG_SPECIAL_RUN=1 \
#     -DH5_LDOUBLE_TO_LONG_SPECIAL_RUN__TRYRUN_OUTPUT= \
#     -DH5_LONG_TO_LDOUBLE_SPECIAL_RUN=1 \
#     -DH5_LONG_TO_LDOUBLE_SPECIAL_RUN__TRYRUN_OUTPUT= \
#     -DH5_LDOUBLE_TO_LLONG_ACCURATE_RUN=1 \
#     -DH5_LDOUBLE_TO_LLONG_ACCURATE_RUN__TRYRUN_OUTPUT= \
#     -DH5_LLONG_TO_LDOUBLE_CORRECT_RUN=1 \
#     -DH5_LLONG_TO_LDOUBLE_CORRECT_RUN__TRYRUN_OUTPUT= \
#     -DH5_DISABLE_SOME_LDOUBLE_CONV_RUN=1 \
#     -DH5_DISABLE_SOME_LDOUBLE_CONV_RUN__TRYRUN_OUTPUT= \
#     ..
# cmake --build . --config RelWithDebInfo --parallel ${nproc}
# cmake --build . --config RelWithDebInfo --parallel ${nproc} --target install

# Required for x86_64-linux-musl. Some HDF5 C code is C99, but configure only requests C89.
export CFLAGS="${CFLAGS} -std=c99"

../configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-hl=yes \
    --enable-static=no \
    --enable-tests=no \
    --enable-tools=yes \
    --with-examplesdir=/tmp \
    hdf5_cv_ldouble_to_long_special=no \
    hdf5_cv_long_to_ldouble_special=no \
    hdf5_cv_ldouble_to_llong_accurate=no \
    hdf5_cv_llong_to_ldouble_correct=no \
    hdf5_cv_disable_some_ldouble_conv=yes

# Patch the generated `Makefile`:
# (We could instead patch `Makefile.in`, or maybe even `Makefile.am`.)
# - HDF5 would also try to build and run `H5detect` to collect ABI information.
#   We know this information, and thus can provide it manually.
# - HDF5 would try to build and run `H5make_libsettings` to collect
#   build-time information. That information seems entirely optional, so
#   we do mostly nothing instead.
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/Makefile.patch

# `AM_V_P` is not defined. This must be a shell command that returns
# true or false depending on whether `make` should be verbose. This is
# probably caused by a bug in automake, or in how automake was used.
make -j${nproc} AM_V_P=:

make install

install_license ../COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Platforms:
# aarch64-apple-darwin
# aarch64-linux-gnu
# aarch64-linux-musl
# armv6l-linux-gnueabihf
# armv6l-linux-musleabihf
# armv7l-linux-gnueabihf
# armv7l-linux-musleabihf
# i686-linux-gnu
# i686-linux-musl
# i686-w64-mingw32
# powerpc64le-linux-gnu
# x86_64-apple-darwin
# x86_64-linux-gnu
# x86_64-linux-musl
# x86_64-unknown-freebsd
# x86_64-w64-mingw32

# The products that we will ensure are always built
products = [
    # HDF5 tools
    ExecutableProduct("h5cc", :h5cc),
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
    ExecutableProduct("h5redeploy", :h5redeploy),
    ExecutableProduct("h5repack", :h5repack),
    ExecutableProduct("h5repart", :h5repart),
    ExecutableProduct("h5stat", :h5stat),
    ExecutableProduct("h5unjam", :h5unjam),
    ExecutableProduct("h5watch", :h5watch),

    # HDF5 libraries
    LibraryProduct("libhdf5", :libhdf5),
    LibraryProduct("libhdf5_hl", :libhdf5_hl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD 
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else. 
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
