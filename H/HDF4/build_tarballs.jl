# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "HDF4"
# We bumped the version number to build without NetCDF support. This
# is necessary to avoid a name clash when using HDF4_jll and
# NetCDF_jll together.
hdf4_version = v"4.3.0"
version = v"4.3.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/HDFGroup/hdf4/releases/download/hdf$(hdf4_version)/hdf$(hdf4_version).tar.gz",
                  "282b244a819790590950f772095abcaeef405b0f17d2ee1eb5039da698cf938b"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/hdf*
cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DTEST_LFS_WORKS_RUN=0 \
    -DH4_PRINTF_LL_TEST_RUN=0 \
    -DH4_PRINTF_LL_TEST_RUN__TRYRUN_OUTPUT= \
    -DHDF4_BUILD_NETCDF_TOOLS=0 \
    -DHDF4_ENABLE_NETCDF=0 \
    -DHDF4_ENABLE_SZIP_SUPPORT=1
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
    # ExecutableProduct("ncdump", :ncdump),
    # ExecutableProduct("ncgen", :ncgen),
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
