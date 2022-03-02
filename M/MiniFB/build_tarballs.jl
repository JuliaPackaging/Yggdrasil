# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MiniFB"
version = v"0.2.1"

# Collection of sources required to complete build
sources = [
	    GitSource("https://github.com/emoon/minifb.git", "5066489cd81b23b0c79952f7d6f464b20c54867c") #master as of 24Feb2022
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/minifb/
sed -i -e 's/add_library(minifb STATIC/add_library(minifb SHARED/' \
    -e 's/-Wall/-I$ENV{includedir} -Wall/' \
    -e 's/Opengl32/opengl32/' \
    CMakeLists.txt
sed -i -e 's?<gl/gl.h>?<GL/gl.h>?' src/gl/MiniFB_GL.c
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DMINIFB_BUILD_EXAMPLES=OFF \
    -DMINIFB_AVOID_CPP_HEADERS=ON \
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
    Dependency(PackageSpec(name="xkbcommon_jll", uuid="d8fb68d0-12a3-5cfd-a85a-d49703b185fd"))
    Dependency(PackageSpec(name="Libglvnd_jll", uuid="7e76a0d4-f3c7-5321-8279-8d96eeed0f29"))
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0", julia_compat="1.6")
