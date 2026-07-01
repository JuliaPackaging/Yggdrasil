# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "OpenCRG"
version = v"2.0.1"

# OpenCRG's c-api is pure, dependency-free ANSI C99/C11: 11 sources in baselib/src,
# one public header baselib/inc/crgBaseLib.h. Upstream's CMakeLists.txt hardcodes a
# STATIC library and has no dllexport annotations, so rather than patch it we just
# invoke the cross-compiler directly on the sources, as done for e.g. CoreMath/EDFlib.
sources = [
    GitSource("https://github.com/asam-ev/OpenCRG.git", "2530b4e711989acbcfa520e2b99034976afc589c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/OpenCRG*/c-api

mkdir -p "${libdir}" "${includedir}"

# Upstream only links libm on non-Apple Unix (see cmake/OpenCRGCompilerSettings.cmake);
# on macOS libm is part of libSystem, and on Windows the mingw CRT already provides it.
EXTRA_LIBS=""
if [[ "${target}" == *-linux-* ]] || [[ "${target}" == *-freebsd* ]]; then
    EXTRA_LIBS="-lm"
fi

# Upstream never marks symbols for export, so on Windows nothing would be visible in
# the DLL unless we tell the linker to export everything.
EXTRA_LDFLAGS=""
if [[ "${target}" == *-mingw* ]]; then
    EXTRA_LDFLAGS="-Wl,--export-all-symbols"
fi

if [[ "${target}" == *-apple-* ]]; then
    ${CC} ${CFLAGS} -std=c11 -O2 -fPIC -Ibaselib/inc -dynamiclib ${LDFLAGS} \
        -o "${libdir}/libOpenCRG.${dlext}" baselib/src/*.c ${EXTRA_LIBS}
else
    ${CC} ${CFLAGS} -std=c11 -O2 -fPIC -Ibaselib/inc -shared ${LDFLAGS} ${EXTRA_LDFLAGS} \
        -o "${libdir}/libOpenCRG.${dlext}" baselib/src/*.c ${EXTRA_LIBS}
fi

install -Dvm 644 baselib/inc/crgBaseLib.h "${includedir}/crgBaseLib.h"
install_license ../LICENSE ../NOTICE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libOpenCRG", :libOpenCRG),
    FileProduct("include/crgBaseLib.h", :crgBaseLib_h),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
