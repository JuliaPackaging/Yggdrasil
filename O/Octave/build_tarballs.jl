using BinaryBuilder, Pkg

name = "Octave"
version = v"9.2.0"

# Collection of sources required to build Octave
sources = [
   ArchiveSource("https://ftpmirror.gnu.org/octave/octave-9.2.0.tar.gz",	
                  "0636554b05996997e431caad4422c00386d2d7c68900472700fecf5ffeb7c991"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/octave*

# Base configure flags
FLAGS=(
    --prefix="$prefix"
    --build=${MACHTYPE}
    --host="${target}"
    --enable-shared
    --disable-static
)

./configure "${FLAGS[@]}"
make -j${nproc} 
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
#platforms = supported_platforms(; experimental=true) # build on all supported platforms
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "windows"),
]


# The products that we will ensure are always built
products = [
    LibraryProduct("liboctave", :liboctave),
    ExecutableProduct("octave", :octave),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("CompilerSupportLibraries_jll")
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")
