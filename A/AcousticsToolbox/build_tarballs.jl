# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "AcousticsToolbox"
version = v"2020.11.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://oalib.hlsresearch.com/AcousticsToolbox/at_2020_11_4.zip", "6f9fe5d3d7fd99fc34fb2a2c3308f2e660a1cc0ea93f0651111af698acf442f0")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
rm -rf __MACOSX
cd at_2020_11_4
perl -p -i -e 's/\-march=native//; s/\-ffast\-math//; s/\-mtune=native//;' Makefile
find . -name *.exe -exec rm {} \;
make
mkdir -p $bindir
find . -name *.exe -exec cp {} $bindir \;
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("field3d.exe", :field3d),
    ExecutableProduct("field.exe", :field),
    ExecutableProduct("kraken.exe", :kraken),
    ExecutableProduct("krakenc.exe", :krakenc),
    ExecutableProduct("bellhop3d.exe", :bellhop3d),
    ExecutableProduct("sparc.exe", :sparc),
    ExecutableProduct("scooter.exe", :scooter),
    ExecutableProduct("bounce.exe", :bounce),
    ExecutableProduct("bellhop.exe", :bellhop)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
