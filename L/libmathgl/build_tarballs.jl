# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libmathgl"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://sourceforge.net/projects/mathgl/files/mathgl/mathgl%202.4.4/mathgl-2.4.4.tar.gz", "0e5977196635962903eaff9b2f759e5b89108339b6e71427036c92bfaf3149e9")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd mathgl-2.4.4/ 
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -Denable-openmp=OFF -Denable-png=ON -Denable-opengl=OFF

export PATH="$PATH:."
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "windows"; ),
    Platform("x86_64", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libmgl", :lib_mgl),
    ExecutableProduct("mgl.cgi", :mgl_cgi, "lib/cgi-bin"),
    ExecutableProduct("mgltask", :mgltask),
    ExecutableProduct("mglconv", :mglconv)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libpng_jll", uuid="b53b4c65-9356-5827-b1ea-8c7a1a84506f"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
