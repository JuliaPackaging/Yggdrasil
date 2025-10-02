
# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "AcousticsToolbox"
version = VersionNumber("2025.9.6")

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://oalib.hlsresearch.com/AcousticsToolbox/at_2024_12_25.zip", "7b57e80bded7f71ea9536e541029615f3f430e390651d697a2212569cbafd85c")
    ArchiveSource("https://oalib-acoustics.org/website_resources/Modes/orca/mac_linux/ORCA_Mode_modelling_gfortran.zip", "4ac15c1374e08bedd0dd03fd5f79612a8f84899ebf529237e662d7efb1dfb10a")
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/at
rm -rf ../__MACOSX
perl -p -i -e 's/^export FFLAGS=.*apple.*$/export FFLAGS= -Bstatic -Waliasing -Wampersand -Wintrinsics-std -Wno-tabs -Wintrinsic-shadow -Wline-truncation -std=gnu -O1 -funroll-all-loops -fomit-frame-pointer/;' Makefile
make clean
make
mkdir -p $bindir
find . -name *.exe -exec cp {} $bindir \;
cd $WORKSPACE/srcdir/ORCA_Mode_modelling_gfortran/src
perl -p -i -e 's/\r\n/\n/g;' cw_modes.f
atomic_patch -p1 $WORKSPACE/srcdir/patches/cw_modes.patch
rm -f *.o *.mod ../bin/*
# don't add -j as it fails
make
# install script fails on libfortran3 and libfortran4 on w64 where .exe is not added during compilation
# install -Dvm 755 "../bin/orca90${exeext}" "${bindir}/orca90.exe"
install -Dvm 755 ../bin/orca90* "${bindir}/orca90.exe"
install_license $WORKSPACE/srcdir/at/LICENSE
install_license $WORKSPACE/srcdir/licenses/LICENSE-orca.txt
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
    ExecutableProduct("bellhop.exe", :bellhop),
    ExecutableProduct("orca90.exe", :orca)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
