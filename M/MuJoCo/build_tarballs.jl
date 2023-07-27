# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "MuJoCo"
version = v"2.3.7"

# Collection of sources required to build libX11
sources = [
    GitSource("https://github.com/deepmind/mujoco", "c9246e1f5006379d599e0bcddf159a8616d31441")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mujoco
sed -i '/Werror/d' cmake/MujocoOptions.cmake
CPPFLAGS="-I${prefix}/include"
CXXFLAGS="-I${prefix}/include"
apk update
apk upgrade
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release .
cmake --build .
cmake --install .
"""
# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if !Sys.isapple(p) || p.tags["arch"] != "aarch64"]
products = [
    LibraryProduct("libmujoco", :libmujuco),
    ExecutableProduct("basic", :mujoco_basic),
    ExecutableProduct("compile", :mujoco_compile),
    ExecutableProduct("derivative", :mujoco_derivative),
    ExecutableProduct("record", :mujoco_record),
    ExecutableProduct("simulate", :mujoco_simulate),
    ExecutableProduct("testspeed", :mujoco_testspeed),
    ExecutableProduct("testxml", :mujoco_testxml),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_libX11_jll"),
    BuildDependency("Xorg_xorgproto_jll"),
    BuildDependency("GLFW_jll"),
    BuildDependency("Xorg_libXrandr_jll"),
    BuildDependency("Libglvnd_jll"),
    BuildDependency("Xorg_libXi_jll"),
    BuildDependency("Xorg_libXinerama_jll"),
    BuildDependency("Xorg_libXcursor_jll")
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"11.1.0")
