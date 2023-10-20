# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "HDF4"
version = v"4.2.16"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://support.hdfgroup.org/ftp/HDF/releases/HDF4.2.16-2/src/hdf-4.2.16-2.tar.gz", "a24b18312d421686031c2d66635f7d5abb2fe879f8a182b7e02797b0da8d1f6c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/hdf*
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DTEST_LFS_WORKS_RUN=0 \
    -DH4_PRINTF_LL_TEST_RUN=0 \
    -DH4_PRINTF_LL_TEST_RUN__TRYRUN_OUTPUT= \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# /opt/x86_64-unknown-freebsd13.2/x86_64-unknown-freebsd13.2/sys-root/usr/include/rpc/xdr.h:125:2: error: unknown type name 'u_int'
filter!(!Sys.isfreebsd, platforms)
# /workspace/srcdir/hdf-4.2.16-2/mfhdf/xdr/types.h:68:18: error: conflicting types for ‘u_quad_t’
filter!(p -> !(libc(p) == "musl" && nbits(p) == 64), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libhdf", :libhdf),
    LibraryProduct("libmfhdf", :libmfhdf)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="JpegTurbo_jll", uuid="aacddb02-875f-59d6-b918-886e6ef4fbf8"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
