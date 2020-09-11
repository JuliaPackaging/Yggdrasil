# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MiniFB"
version = v"0.1.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/emoon/minifb.git", "dda1275bd741752d1b7cdc1ee4d9941887a1891a") #master as of 10Sep2020
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/minifb/
sed -i -e 's/add_library(minifb STATIC/add_library(minifb SHARED/' \
    -e 's/ -Wall/-I$ENV{includedir} -Wall/' \
    CMakeLists.txt
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DMINIFB_BUILD_EXAMPLES=OFF \
    ..
make -j${nproc}
mv libminifb* ${libdir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libminifb", :libminifb)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Xorg_libX11_jll", uuid="4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"))
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0")
