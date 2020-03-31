# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CALCEPH"
version = v"3.4.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.imcce.fr/content/medias/recherche/equipes/asd/calceph/calceph-3.4.2.tar.gz", "4bb95979ed77f431c6845b11b7bc49819836e47a8b9ceceff18309683f580c5b")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd calceph-3.4.2/
if [[ ${target} == i686-w64* ]] || [[ ${target} == x86_64-w64* ]]; then
    echo 'LT_INIT([win32-dll])' >> configure.ac;
    sed -i '/^libcalceph_la_LDFLAGS/ s/$/ -no-undefined/' src/Makefile.am;
fi
autoreconf -fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-fortran=no --enable-python=no --disable-static
make -j${nproc}
make install
install_license ${WORKSPACE}/srcdir/calceph-3.4.2/COPYING_CECILL_B.LIB
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcalceph", :libcalceph)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
