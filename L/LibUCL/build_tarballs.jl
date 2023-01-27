using BinaryBuilder

name = "LibUCL"
version = v"0.8.2"

sources = [GitSource("https://github.com/vstakhov/libucl.git",
                     "a615938cec3ae35c70aa2fb9845c9c12e5c7326f")]

script = raw"""
cd ${WORKSPACE}/srcdir/libucl*
if [[ "${target}" == *-mingw* ]]; then
    cp "${includedir}/pcreposix.h" "${includedir}/regex.h"
    sed -i 's/-lregex/-lpcreposix-0/' configure
fi
./autogen.sh
./configure \
    --enable-urls \
    --enable-shared \
    --disable-static \
    --prefix="${prefix}" \
    --build="${MACHTYPE}" \
    --host="${target}"
make -j${nproc}
make install
"""

platforms = supported_platforms()

products = [LibraryProduct("libucl", :libucl)]

dependencies = [Dependency("LibCURL_jll")]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
