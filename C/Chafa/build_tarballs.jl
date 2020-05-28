using BinaryBuilder

name = "Chafa"
version = v"1.4.1"

sources = [
    ArchiveSource("https://hpjansson.org/chafa/releases/chafa-$(version).tar.xz",
                  "46d34034f4c96d120e0639f87a26590427cc29e95fe5489e903a48ec96402ba3"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/chafa-*/
./autogen.sh --prefix=${prefix} --host=${target}
make -j${nproc}
make install
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libchafa", :libchafa),
    ExecutableProduct("chafa", :chafa),
]

dependencies = [
    Dependency("FreeType2_jll"),
    Dependency("Glib_jll"),
    Dependency("ImageMagick_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
