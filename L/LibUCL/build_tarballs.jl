using BinaryBuilder

name = "LibUCL"
version = v"0.9.2"

sources = [
    GitSource("https://github.com/vstakhov/libucl.git",
              "16498fcfb0148963feecf0401dc6d2d5089cebdf")
]

script = raw"""
cd ${WORKSPACE}/srcdir/libucl*
./autogen.sh
FLAGS=()
if [[ "${target}" == *-mingw* ]]; then
    cp "${includedir}/pcreposix.h" "${includedir}/regex.h"
    sed -i 's/-lregex/-lpcreposix-0/' configure
    export LIBS="-lpcreposix-0"
    export LDFLAGS="-L${libdir}"
    FLAGS+=(LDFLAGS="${LDFLAGS} -no-undefined")
fi
./configure \
    --enable-urls \
    --enable-shared \
    --disable-static \
    --prefix="${prefix}" \
    --build="${MACHTYPE}" \
    --host="${target}"
make -j${nproc} "${FLAGS[@]}"
make install

if [[ "${target}" == *-mingw* ]]; then
    # Cover up the traces of the hack
    rm "${includedir}/regex.h"
fi
"""

platforms = supported_platforms()

products = [LibraryProduct("libucl", :libucl)]

dependencies = [
    Dependency("LibCURL_jll"; compat="7.73,8"),
    Dependency("PCRE_jll"; platforms=filter(Sys.iswindows, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
