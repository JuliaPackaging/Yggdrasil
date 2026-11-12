using BinaryBuilder

name = "OpenCRG"
version = v"2.0.1"

# Upstream's CMake only builds a static lib with no dllexport annotations,
# so this compiles baselib/src directly into a shared lib instead.
sources = [
    GitSource("https://github.com/asam-ev/OpenCRG.git", "2530b4e711989acbcfa520e2b99034976afc589c"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/OpenCRG*/c-api

mkdir -p "${libdir}" "${includedir}"

# Matches upstream: libm is linked only on non-Apple Unix targets.
EXTRA_LIBS=""
if [[ "${target}" == *-linux-* ]] || [[ "${target}" == *-freebsd* ]]; then
    EXTRA_LIBS="-lm"
fi

# Export all symbols: upstream marks none, so Windows needs this for a DLL.
EXTRA_LDFLAGS=""
if [[ "${target}" == *-mingw* ]]; then
    EXTRA_LDFLAGS="-Wl,--export-all-symbols"
fi

${CC} ${CFLAGS} -std=c11 -O2 -fPIC -Ibaselib/inc -shared ${LDFLAGS} ${EXTRA_LDFLAGS} \
    -o "${libdir}/libOpenCRG.${dlext}" baselib/src/*.c ${EXTRA_LIBS}
install -Dvm 644 baselib/inc/crgBaseLib.h "${includedir}/crgBaseLib.h"
install_license ../LICENSE ../NOTICE
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libOpenCRG", :libOpenCRG),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
