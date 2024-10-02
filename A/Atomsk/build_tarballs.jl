# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Atomsk"
version = v"0.12.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pierrehirel/atomsk.git", "258c75779adc828a947c8366012f75a66d3b8c5e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/atomsk

export ATOMSKLIB=$libdir/libatomsk.$dlext
export LAPACK=-lopenblas
if [[ "$target" == *mingw* ]]; then
    export LDFLAGS="-L${libdir}"
fi
cd src

# The makefile doesn't handle parallel builds
mkdir -p $bindir
make shared=yes clib
cp atomsk$exeext $bindir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)
platforms = filter(p -> !(Sys.isfreebsd(p) || libc(p) == "musl"), platforms)
# Atomsk is not supported for libgfortran versions less than 5
platforms = filter(p -> libgfortran_version(p) >= v"5", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libatomsk", :libatomsk),
    ExecutableProduct("atomsk", :atomsk)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")
