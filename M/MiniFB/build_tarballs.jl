# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MiniFB"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/emoon/minifb.git", "2110dc18ac93a531bd832b323ea92a1622430e1c") #master as of 15Aug2020
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd minifb/
sed -i 's/add_library(minifb STATIC/add_library(minifb SHARED/' CMakeLists.txt
mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DMINIFB_BUILD_EXAMPLES=OFF ..
make -j${nproc}
mv libminifb* ${libdir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64),
]


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
