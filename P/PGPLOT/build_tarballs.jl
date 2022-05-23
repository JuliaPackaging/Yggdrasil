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
make lib SHARED_LD="${FC} -shared  -o libpgplot.${dlext}"
cp libpgplot.so "${libdir}/libpgplot.so"
install_license ../pgplot/copyright.notice
"""

platforms = [
    Platform("x86_64", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="glibc"),
]
platforms = expand_gfortran_versions(platforms)

products = [LibraryProduct("libpgplot", :libpgplot)]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
