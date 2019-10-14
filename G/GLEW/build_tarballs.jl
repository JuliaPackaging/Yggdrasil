# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GLEW"
version = v"2.1.0"

# Collection of sources required to build GLEW
sources = [
    "https://github.com/nigels-com/glew/releases/download/glew-$(version)/glew-$(version).tgz" =>
    "04de91e7e6763039bc11940095cd9c7f880baba82196a7765f727ac05a993c95"
]

# Bash recipe for building across all platforms
builddir = "glew-$(version)"
script = """
cd \$WORKSPACE/srcdir

cd $builddir
make glew.lib.shared INCLUDE="-Iinclude -I\${prefix}/include"
cp -r lib \${prefix}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc)
]

# The products that we will ensure are always built
products = [
    LibraryProduct(["libglew", "libGLEW"], :libGLEW),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Libglvnd_jll",
    "X11_jll"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
