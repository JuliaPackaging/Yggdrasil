using BinaryBuilder, Pkg

name = "libgeotiff"
version = v"1.7.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/OSGeo/libgeotiff/releases/download/$version/libgeotiff-$version.tar.gz",
                  "fc304d8839ca5947cfbeb63adb9d1aa47acef38fc6d6689e622926e672a99a7e"),
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

# same fix as used for PROJ
if [[ "${target}" == x86_64-linux-musl* ]]; then
    export LDFLAGS="$LDFLAGS -lcurl"
fi

cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      ..

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libgeotiff", :libgeotiff),
    ExecutableProduct("makegeo", :makegeo),
    ExecutableProduct("geotifcp", :geotifcp),
    ExecutableProduct("listgeo", :listgeo),
    ExecutableProduct("applygeo", :applygeo),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("PROJ_jll"; compat="~800.200"),
    Dependency("Libtiff_jll"; compat="4.3"),
    Dependency("LibCURL_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
