# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "eccodes"
version = v"2.17.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://confluence.ecmwf.int/download/attachments/45757960/eccodes-2.17.0-Source.tar.gz", "762d6b71993b54f65369d508f88e4c99e27d2c639c57a5978c284c49133cc335"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd eccodes-2.17.0-Source
if [ ${target} = "x86_64-w64-mingw32" ] || [ ${target} = "i686-w64-mingw32" ] ; then 
    chmod +x cmake/ecbuild_windows_replace_symlinks.sh 
    atomic_patch -p1 /workspace/srcdir/patches/windows.patch
else
    atomic_patch -p1 /workspace/srcdir/patches/unix.patch
fi
cd ..
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DENABLE_NETCDF=OFF -DENABLE_PNG=ON -DENABLE_PYTHON=OFF -DENABLE_FORTRAN=OFF -DENABLE_MEMFS=ON ../eccodes-2.17.0-Source/
make -j${nproc}
make install
install_license ../eccodes-2.17.0-Source/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms() 

# The products that we will ensure are always built
products = [
    LibraryProduct("libeccodes", :eccodes)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libpng_jll", uuid="b53b4c65-9356-5827-b1ea-8c7a1a84506f"))
    Dependency(PackageSpec(name="OpenJpeg_jll", uuid="643b3616-a352-519d-856d-80112ee9badc"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
