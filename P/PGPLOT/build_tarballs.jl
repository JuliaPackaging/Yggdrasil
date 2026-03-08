# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PGPLOT"
version = v"5.2.2"

sources = [
    ArchiveSource("ftp://ftp.astro.caltech.edu/pub/pgplot/pgplot5.2.tar.gz", "a5799ff719a510d84d26df4ae7409ae61fe66477e3f1e8820422a9a4727a5be4"),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir

# Apply patches to pgplot source
pushd pgplot
for f in ../patch-*.diff; do
    atomic_patch -p0 "${f}"
done
# Fix pndriv.c for modern libpng (png_struct is opaque since libpng 1.5)
sed -i 's|png_ptr->jmpbuf|png_jmpbuf(png_ptr)|' drivers/pndriv.c
popd

if [[ "${target}" == *-apple-* ]]; then
    pushd pgplot
    mkdir sys_darwin
    cp ../bb.conf ./sys_darwin/bb.conf
    popd
fi

mkdir pgplot_build && cd pgplot_build/
cat ../pgplot/drivers.list | sed 's|! PSDRIV|  PSDRIV|g' | sed 's|! GIDRIV|  GIDRIV|g' | sed 's|! PNDRIV|  PNDRIV|g' > drivers.list

if [[ "${target}" == *-apple-* ]]; then
    ../pgplot/makemake ../pgplot/ darwin
    make lib SHELL=/bin/bash
else
    ../pgplot/makemake ../pgplot/ linux g77_gcc
    sed -i 's|FCOMPL=g77|FCOMPL=gfortran|' makefile
    sed -i 's|^SHARED_LIB_LIBS=.*|SHARED_LIB_LIBS=-lpng -lz|' makefile
    # Symlink libpng/zlib headers so the Makefile's local header dependencies resolve
    ln -sf ${includedir}/png.h ${includedir}/pngconf.h ${includedir}/pnglibconf.h .
    ln -sf ${includedir}/zlib.h ${includedir}/zconf.h .
    make lib SHARED_LD="${FC} -shared  -o libpgplot.${dlext}"
fi

# Build grfont.dat using host (musl) Fortran compiler so pgpack can run in the sandbox
/opt/x86_64-linux-musl/bin/x86_64-linux-musl-gfortran -o pgpack ../pgplot/fonts/pgpack.f
./pgpack < ../pgplot/fonts/grfont.txt
make rgb.txt

install -Dvm 755 libpgplot.${dlext} "${libdir}/libpgplot.${dlext}"
install -Dvm 644 grfont.dat "${prefix}/share/pgplot/grfont.dat"
install -Dvm 644 rgb.txt "${prefix}/share/pgplot/rgb.txt"
install_license ../pgplot/copyright.notice
"""

platforms = [
    Platform("x86_64", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="glibc"),
    Platform("aarch64", "macos"),
]
platforms = expand_gfortran_versions(platforms)

products = [
    LibraryProduct("libpgplot", :libpgplot),
    FileProduct("share/pgplot/grfont.dat", :grfont_dat),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="libpng_jll", uuid="b53b4c65-9356-5827-b1ea-8c7a1a84506f")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6",
    init_block = raw"""
    # need to set because PGPLOT searches for grfot.dat only via (i) PGPLOT_FONT (ii) PGPLOT_DIR (iii) comptime default path
    ENV["PGPLOT_FONT"] = grfont_dat
""")
