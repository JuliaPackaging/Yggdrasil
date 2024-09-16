# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Atomsk"
version = v"0.12.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pierrehirel/atomsk.git", "84f60a20c5b814fec03bffe1bccc3daaed0fc65d"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/atomsk
if [[ "$nbits" == 32 || "$target" == *apple* ]]; then
    atomic_patch -p1 ../patches/atomsk_32.patch
else
    atomic_patch -p1 ../patches/atomsk_64.patch
fi
if [[ "$target" == *mingw* ]]; then
    ln -s $prefix/bin/libatomsk.dll $prefix/lib/libatomsk.dll
fi
cd src

# The makefile doesn't handle parallel builds
if [[ ! -d "$bindir" ]]; then
    mkdir ${bindir}
fi
make atomsk
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
platforms = filter(p -> !(Sys.isfreebsd(p) || libc(p) == "musl"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libatomsk", :libatomsk),
    ExecutableProduct("atomsk", :atomsk)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="LAPACK_jll", uuid="51474c39-65e3-53ba-86ba-03b1b862ec14")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")
