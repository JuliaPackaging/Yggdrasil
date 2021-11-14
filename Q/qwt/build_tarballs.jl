# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "qwt"
version = v"6.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ig-or/qwt.git", "30812fc4a2630ec9956f4daa6c4f6d4b331c74a6")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/qwt
qmake
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "windows"),
    Platform("x86_64", "linux"; libc="glibc"),
]


# The products that we will ensure are always built
products = [
    LibraryProduct(["libqwt", "qwt"], :qwt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # TODO: in the future replace `Qt_jll` with `Qt5Base_jll` + `Qt5Svg_jll`
    Dependency(PackageSpec(name="Qt_jll", uuid="ede63266-ebff-546c-83e0-1c6fb6d0efc8"))
    Dependency(PackageSpec(name="GLEW_jll", uuid="bde7f898-03f7-559e-8810-194d950ce600"))
    Dependency(PackageSpec(name="GLFW_jll", uuid="0656b61e-2033-5cc2-a64a-77c0f6c09b89"))
    Dependency(PackageSpec(name="GLU_jll", uuid="bd17208b-e95e-5925-bf81-e2f59b3e5c61"))
]

include("../../fancy_toys.jl")

platforms_linux = filter(p -> Sys.islinux(p), platforms)
platforms_win = filter(p -> Sys.iswindows(p), platforms)

if any(should_build_platform.(triplet.(platforms_linux)))
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7")
end
if any(should_build_platform.(triplet.(platforms_win)))
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8")
end
