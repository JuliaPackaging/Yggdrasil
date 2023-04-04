# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SCOTCH"
version = v"7.0.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gitlab.inria.fr/scotch/scotch/-/archive/v$(version)/scotch-v$(version).tar.gz",
                  "5b5351f0ffd6fcae9ae7eafeccaa5a25602845b9ffd1afb104db932dd4d4f3c5")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/scotch*
mkdir build
cd build


CFLAGS="-lrt -lgcc_s -fPIC" cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DINTSIZE="32" \
    -DTHREADS=ON \
    -DMPI_THREAD_MULTIPLE=OFF \
    -DBUILD_PTSCOTCH=OFF \
    -DBUILD_LIBESMUMPS=ON \
    -DBUILD_LIBSCOTCHMETIS=ON \
    -DINSTALL_METIS_HEADERS=OFF ..

make -j${nproc}
make install

install_license ../LICENSE_en.txt

cd $libdir
$CC -shared -I$libdir $(flagon -Wl,--whole-archive) libscotch.a $(flagon -Wl,--no-whole-archive) -o ${libdir}/libscotch.${dlext}
$CC -shared $(flagon -Wl,--whole-archive) libesmumps.a $(flagon -Wl,--no-whole-archive) -o ${libdir}/libesmumps.${dlext}
$CC -shared $(flagon -Wl,--whole-archive) libscotcherr.a $(flagon -Wl,--no-whole-archive) -o ${libdir}/libscotcherr.${dlext}
$CC -shared $(flagon -Wl,--whole-archive) libscotcherrexit.a $(flagon -Wl,--no-whole-archive) -o ${libdir}/libscotcherrexit.${dlext}
$CC -shared $(flagon -Wl,--whole-archive) libscotchmetisv3.a $(flagon -Wl,--no-whole-archive) -o ${libdir}/libscotchmetisv3.${dlext}
$CC -shared $(flagon -Wl,--whole-archive) libscotchmetisv5.a $(flagon -Wl,--no-whole-archive) -o ${libdir}/libscotchmetisv5.${dlext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows)

# The products that we will ensure are always built
products = [
    LibraryProduct("libscotch", :libscotch),
    LibraryProduct("libesmumps", :libesmumps),
    LibraryProduct("libscotcherr", :libscotcherr),
    LibraryProduct("libscotcherrexit", :libscotcherrexit),
    LibraryProduct("libscotchmetisv3", :libscotchmetisv3),
    LibraryProduct("libscotchmetisv5", :libscotchmetisv5)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
    Dependency(PackageSpec(name="Bzip2_jll", uuid="6e34b625-4abd-537c-b88f-471c36dfa7a0")),
    Dependency(PackageSpec(name="XZ_jll", uuid="ffd25f8a-64ca-5728-b0f7-c24cf3aae800"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9.1.0", julia_compat="1.6")
