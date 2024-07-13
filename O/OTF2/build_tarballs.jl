using BinaryBuilder

name = "OTF2"
version = v"3.0.3"
sources = [
    ArchiveSource("https://perftools.pages.jsc.fz-juelich.de/cicd/otf2/tags/otf2-$version/otf2-$version.tar.gz", "18a3905f7917340387e3edc8e5766f31ab1af41f4ecc5665da6c769ca21c4ee8"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/otf2-*

autoreconf -fvi
./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-shared \
    --disable-static \
    --without-python \
    --disable-doc \
    --disable-doxygen-doc \
    --disable-doxygen-dot \
    --disable-doxygen-html \
    --disable-doxygen-rtf

make -j${nproc}
make install V=1
"""

# NOTE cross-compilation is not working because `--host` is not getting propagated
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
]

dependencies = Dependency[]

products = [
    LibraryProduct("libotf2", :libotf2),
    ExecutableProduct("otf2-config", :otf2_config),
    ExecutableProduct("otf2-estimator", :otf2_estimator),
    ExecutableProduct("otf2-marker", :otf2_marker),
    ExecutableProduct("otf2-print", :otf2_print),
    ExecutableProduct("otf2-snapshots", :otf2_snapshots),
]

build_tarballs(ARGS, name, version, sources, script, platforms,
    products, dependencies; julia_compat="1.6")
