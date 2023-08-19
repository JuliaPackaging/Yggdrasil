# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "MuJoCo"
version = v"2.3.7"

# Collection of sources required to build mujoco
sources = [
    GitSource("https://github.com/deepmind/mujoco", "c9246e1f5006379d599e0bcddf159a8616d31441"),
    DirectorySource(joinpath(@__DIR__, "patches"))
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mujoco
if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 ../mingw.patch
elif [[ "${target}" == *-apple-darwin* ]]; then
    atomic_patch -p1 ../macos.patch
else
    atomic_patch -p1 ../other.patch
fi
CPPFLAGS="-I${prefix}/include"
CXXFLAGS="-I${prefix}/include"
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release .
cmake --build .
cmake --install .
"""
# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
function platform_filer(p)
    return contains(p.tags["arch"], "64") && (!haskey(p.tags, "libc") || p.tags["libc"] != "musl") && (!Sys.isbsd(p) || Sys.isapple(p))
end
platforms = [p for p in supported_platforms() if platform_filer(p)]

products = [
    LibraryProduct("libmujoco", :libmujoco)
]

linux_platforms = [p for p in platforms if Sys.islinux(p) || Sys.isbsd(p)]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_libX11_jll"; platforms=linux_platforms),
    BuildDependency("Xorg_xorgproto_jll"; platforms=linux_platforms),
    BuildDependency("GLFW_jll"; platforms=linux_platforms),
    BuildDependency("Xorg_libXrandr_jll"; platforms=linux_platforms),
    BuildDependency("Libglvnd_jll"; platforms=linux_platforms),
    BuildDependency("Xorg_libXi_jll"; platforms=linux_platforms),
    BuildDependency("Xorg_libXinerama_jll"; platforms=linux_platforms),
    BuildDependency("Xorg_libXcursor_jll"; platforms=linux_platforms)
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"11.1.0")
