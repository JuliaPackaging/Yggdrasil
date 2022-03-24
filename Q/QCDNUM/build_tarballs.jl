# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "QCDNUM"
version = v"18.0.00"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.nikhef.nl/~h24/download/qcdnum180000.tar.gz",
                  "376a2e6d56761c5356b4ff66cf1c47b48e1155efafc53813cc2e6f11747ca98e"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/qcdnum*/
if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 ../patches/link-no-undefined-windows.patch
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
platforms = expand_gfortran_versions(platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libQCDNUM", :libqcdnum)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
