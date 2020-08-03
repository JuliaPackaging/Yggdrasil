# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PGPLOT"
version = v"5.2"

sources = [ArchiveSource("ftp://ftp.astro.caltech.edu/pub/pgplot/pgplot5.2.tar.gz", "a5799ff719a510d84d26df4ae7409ae61fe66477e3f1e8820422a9a4727a5be4")]

script = raw"""
cd $WORKSPACE/srcdir
mkdir pgplot_build && cd pgplot_build/
cat ../pgplot/drivers.list | sed 's|! PSDRIV|  PSDRIV|g' | sed 's|! GIDRIV|  GIDRIV|g' > drivers.list
../pgplot/makemake ../pgplot/ linux g77_gcc
sed -i 's|FCOMPL=g77|FCOMPL=gfortran|' makefile
make
cp libpgplot.so $libdir
install_license ../pgplot/copyright.notice
"""

platforms = [
    Linux(:x86_64, libc=:musl),
    Linux(:x86_64, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:i686, libc=:glibc),
]

products = [LibraryProduct("libpgplot", :libpgplot)]

dependencies = [
    Dependency(PackageSpec(name="Xorg_libX11_jll", uuid="4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
