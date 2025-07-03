# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "HDF4"
# We bumped the version number to build without NetCDF support.
hdf4_version = v"4.3.1"
version = v"4.3.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/HDFGroup/hdf4/releases/download/hdf$(hdf4_version)/hdf$(hdf4_version).tar.gz",
                  "a2c69eb752aee385b73d4255e4387134dd5e182780d64da0a5cb0d6e1d3dea3b"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/hdf*

# We need to build without NetCDF support. This is necessary to avoid
# a name clash when using HDF4_jll and NetCDF_jll together.
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DTEST_LFS_WORKS_RUN=0 \
    -DH4_PRINTF_LL_TEST_RUN=0 \
    -DH4_PRINTF_LL_TEST_RUN__TRYRUN_OUTPUT= \
    -DHDF4_BUILD_NETCDF_TOOLS=0 \
    -DHDF4_ENABLE_NETCDF=0 \
    -DHDF4_ENABLE_SZIP_SUPPORT=1

# On Windows, HDF4 finds libaec, but the generated Makefile still says "NOTFOUND".
# (This problem exists also for HDF5 and is described in detail there.)
# We fix the generated Makefile etc manually.

files=(
    build/hdf/src/CMakeFiles/hdf-shared.dir/build.make
    build/hdf/src/CMakeFiles/hdf-shared.dir/linklibs.rsp
    build/hdf/test/CMakeFiles/testhdf.dir/build.make
    build/hdf/test/CMakeFiles/testhdf.dir/linklibs.rsp
    build/mfhdf/hrepack/CMakeFiles/hrepack.dir/build.make
    build/mfhdf/hrepack/CMakeFiles/hrepack.dir/linklibs.rsp
    build/mfhdf/hrepack/CMakeFiles/test_hrepack.dir/build.make
    build/mfhdf/hrepack/CMakeFiles/test_hrepack.dir/linklibs.rsp
)
for file in ${files[@]}; do
    perl -pi -e 's+libaec::aec-NOTFOUND+/workspace/destdir/lib/libaec.dll.a+' ${file}
    perl -pi -e 's+libaec::sz-NOTFOUND+/workspace/destdir/lib/libsz.dll.a+' ${file}
done

cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    # ExecutableProduct("h4cc", :h4cc),   # `h4cc` is not built on Windows
    ExecutableProduct("hdfed", :hdfed),
    ExecutableProduct("hdfimport", :hdfimport),
    ExecutableProduct("hdfls", :hdfls),
    ExecutableProduct("hdiff", :hdiff),
    ExecutableProduct("hdp", :hdp),
    ExecutableProduct("hrepack", :hrepack),
    LibraryProduct("libhdf", :libhdf),
    LibraryProduct("libmfhdf", :libmfhdf),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="JpegTurbo_jll", uuid="aacddb02-875f-59d6-b918-886e6ef4fbf8"); compat="3.1.1"),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"); compat="1.2.12"),
    Dependency(PackageSpec(name="libaec_jll", uuid="477f73a3-ac25-53e9-8cc3-50b2fa2566f0"); compat="1.1.3"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
