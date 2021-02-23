# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MathGL"
version = v"2.4.5"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://sourceforge.net/projects/mathgl/files/mathgl/mathgl%202.4.4/mathgl-2.4.4.tar.gz", "0e5977196635962903eaff9b2f759e5b89108339b6e71427036c92bfaf3149e9"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
apk add g++
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd mathgl-2.4.4/
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -Denable-all-docs=OFF -Denable-qt5=ON -Denable-qt4=OFF -Denable-mpi=OFF  ../.
make -j
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "windows"),
    Platform("x86_64", "linux"; libc="glibc"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmgl-qt5", :mgl_qt5),
    LibraryProduct("libmgl", :mgl),
    LibraryProduct("libmgl-qt", :mgl_qt)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Qt_jll", uuid="ede63266-ebff-546c-83e0-1c6fb6d0efc8"))
    Dependency(PackageSpec(name="libpng_jll", uuid="b53b4c65-9356-5827-b1ea-8c7a1a84506f"))
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4"))
    Dependency(PackageSpec(name="Libglvnd_jll", uuid="7e76a0d4-f3c7-5321-8279-8d96eeed0f29"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8.1.0")
