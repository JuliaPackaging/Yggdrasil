using BinaryBuilder

name = "libfabric"
version = v"2.0.0"

sources = [
    GitSource("https://github.com/ofiwg/libfabric", "2ee68f6051e90a59d7550d94a331fdf5e038db90"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/libfabric

./autogen.sh
./configure --build=${MACHTYPE} --host=${target} --prefix=${prefix}
make -j${nproc}
make install
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libfabric", :libfabric),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
