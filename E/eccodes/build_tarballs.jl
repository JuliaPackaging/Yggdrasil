# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "eccodes"
version = v"2.25.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://confluence.ecmwf.int/download/attachments/45757960/eccodes-$version-Source.tar.gz", "8975131aac54d406e5457706fd4e6ba46a8cc9c7dd817a41f2aa64ce1193c04e"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/eccodes-*-Source
if [[ ${target} = *-mingw* ]] ; then
    chmod +x cmake/ecbuild_windows_replace_symlinks.sh
    atomic_patch -p1 /workspace/srcdir/patches/windows.patch
else
    atomic_patch -p1 /workspace/srcdir/patches/unix.patch
fi
atomic_patch -p1 /workspace/srcdir/patches/kinds.patch
mkdir build
cd build
export CFLAGS="-I${includedir}"
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_NETCDF=OFF \
    -DENABLE_PNG=ON \
    -DENABLE_FORTRAN=ON \
    -DENABLE_ECCODES_THREADS=ON \
    -DENABLE_AEC=OFF \
    ..
make -j${nproc}
make install
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)
# The products that we will ensure are always built
products = [
    LibraryProduct("libeccodes", :eccodes),
    LibraryProduct("libeccodes_f90", :libeccodes_f90),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="libpng_jll", uuid="b53b4c65-9356-5827-b1ea-8c7a1a84506f")),
    Dependency(PackageSpec(name="OpenJpeg_jll", uuid="643b3616-a352-519d-856d-80112ee9badc")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
