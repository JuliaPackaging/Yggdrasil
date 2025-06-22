# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "BWA"
version = v"0.7.17"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/lh3/bwa/releases/download/v$(version)/bwa-$(version).tar.bz2",
                  "de1b4d4e745c0b7fc3e107b5155a51ac063011d33a5d82696331ecf4bed8d0fd"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/bwa*/
atomic_patch -p1 ../patches/makefile.patch
atomic_patch -p1 ../patches/0001-Fix-building-against-GCC-10.patch
# Reduce verbosity of the output to only have warnings and errors
sed -i -e 's/int bwa_verbose = 3;/int bwa_verbose = 2;/' bwa.c
make -j${nproc}
mkdir -p "${libdir}" "${bindir}"
cp "bwa${exeext}" "${bindir}/bwa${exeext}"
cp "libbwa.${dlext}" "${libdir}/libbwa.${dlext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = supported_platforms(; experimental=true)
# The package uses Intel intrinsics, so we can build only for Intel platforms.
filter!(p -> BinaryBuilder.proc_family(p) == "intel", platforms)
# ...and uses some Unix header files not available on Windows.
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libbwa", :libbwa),
    ExecutableProduct("bwa", :bwa),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
