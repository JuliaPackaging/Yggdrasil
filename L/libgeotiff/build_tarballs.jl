using BinaryBuilder, Pkg

name = "libgeotiff"
version = v"1.6.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/OSGeo/libgeotiff/releases/download/$version/libgeotiff-$version.tar.gz", "9311017e5284cffb86f2c7b7a9df1fb5ebcdc61c30468fb2e6bca36e4272ebca"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/libgeotiff-*/

# Who knows why they want to install Windows binaries not build with MSVC to
# ${prefix} instead of ${prefix}/bin
atomic_patch -p1 ../patches/more-reasonable-default-bin-subdir.patch

mkdir build && cd build

# Hint to find libstc++, required to link against C++ libs when using C compiler
if [[ "${target}" == *-linux-* ]]; then
    if [[ "${nbits}" == 32 ]]; then
        export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib"
    else
        export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib64"
    fi
fi

cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      ..

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("makegeo", :makegeo),
    ExecutableProduct("geotifcp", :geotifcp),
    ExecutableProduct("listgeo", :listgeo),
    ExecutableProduct("applygeo", :applygeo),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="PROJ_jll", uuid="58948b4f-47e0-5654-a9ad-f609743f8632")),
    Dependency(PackageSpec(name="Libtiff_jll", uuid="89763e89-9b03-5906-acba-b20f662cd828")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
