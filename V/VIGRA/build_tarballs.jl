# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "VIGRA"
version = v"1.11.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/ukoethe/vigra/archive/refs/tags/Version-$(version.major)-$(version.minor)-$(version.patch).tar.gz", "b2718250d28baf1932fcbe8e30f7e4d146e751ad0e726e375a72a0cdb4e3250e"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/vigra-*

#there is a BUILD_DOCS/BUILD_TESTS flag on master now, this can be removed if new release ever?
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/disable-subdirectories.patch

cmake . \
-DCMAKE_INSTALL_PREFIX=$prefix \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release \
-DWITH_OPENEXR=OFF \
-DWITH_HDF5=OFF \
-DWITH_VIGRANUMPY=OFF \
-DCREATE_CTEST_TARGETS=OFF

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libvigraimpex", :libvigraimpex)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
    Dependency(PackageSpec(name="JpegTurbo_jll", uuid="aacddb02-875f-59d6-b918-886e6ef4fbf8"))
    Dependency(PackageSpec(name="Libtiff_jll", uuid="89763e89-9b03-5906-acba-b20f662cd828"))
    Dependency(PackageSpec(name="libpng_jll", uuid="b53b4c65-9356-5827-b1ea-8c7a1a84506f"))
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
