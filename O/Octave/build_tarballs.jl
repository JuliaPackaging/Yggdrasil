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

export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"

if [[ "${target}" == *-mingw* ]]; then
    LBT=blastrampoline-5
else
    LBT=blastrampoline
fi

# Base configure flags
FLAGS=(
    --prefix="$prefix"
    --build=${MACHTYPE}
    --host="${target}"
    --enable-shared
    --disable-static
    --with-blas="-L${prefix}/lib -l${LBT}"
    --with-lapack="-L${prefix}/lib -l${LBT}"
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
    Dependency("CompilerSupportLibraries_jll"),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
    Dependency("PCRE2_jll"),
    Dependency("Readline_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")
