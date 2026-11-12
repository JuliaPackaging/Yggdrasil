# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Tcl"
version = v"9.0.3"

# Collection of sources required to build Tcl
sources = [
    GitSource("https://github.com/tcltk/tcl.git",
              "bcd73c5cf807577f93f890c0efdd577b14a66418"),
]

# Bash recipe for building across all platforms
script = raw"""
# musl needs bsd-compat-headers for sys/queue.h
# Copy header to sysroot since cross-compiler doesn't see /usr/include
if [[ "${target}" == *-musl* ]]; then
    apk add bsd-compat-headers
    cp /usr/include/sys/queue.h /opt/${target}/${target}/sys-root/usr/include/sys/
fi

FLAGS=(--disable-zipfs --enable-threads --disable-rpath)

if [[ "${target}" == x86_64-* ]] || [[ "${target}" == aarch64-* ]]; then
    FLAGS+=(--enable-64bit)
fi

if [[ "${target}" == *-mingw* ]]; then
    # `make install` calls `tclsh` on Windows
    apk add tcl

    # The pre-built libtommath and zlib DLLs in the Tcl source tree were compiled
    # with MSVC (UCRT) but tcl90.dll is cross-compiled with MinGW (msvcrt),
    # causing C runtime mismatch crashes. Fix:
    #  - Cross-compile libtommath from source.
    #  - Use Zlib_jll's zlib (available on the DLL search path at runtime).

    # Cross-compile libtommath from source.
    cd $WORKSPACE/srcdir/tcl/libtommath
    TOMMATH_CFLAGS="-O2 -I. -DTCL_WITH_EXTERNAL_TOMMATH"
    if [[ "${target}" == x86_64-* ]] || [[ "${target}" == aarch64-* ]]; then
        TOMMATH_CFLAGS="${TOMMATH_CFLAGS} -DMP_64BIT"
    fi
    ${CC} ${TOMMATH_CFLAGS} -shared -o libtommath.dll bn_*.c \
        -Wl,--out-implib,libtommath.dll.a
    # Replace pre-built MSVC libtommath and zlib with cross-compiled / Zlib_jll versions.
    # The MSVC import libraries point to zlib1.dll; Zlib_jll's points to libz.dll.
    # Configure sets ZLIB_LIBS per target: win64/libz.dll.a, win64-arm/libz.dll.a,
    # or win32/zdll.lib (no GCC branch for 32-bit in upstream configure).
    if [[ "${target}" == aarch64-*mingw* ]]; then
        cp -f libtommath.dll libtommath.dll.a win64-arm/
        cp -f ${prefix}/lib/libz.dll.a $WORKSPACE/srcdir/tcl/compat/zlib/win64-arm/libz.dll.a
    elif [[ "${target}" == x86_64-*mingw* ]]; then
        cp -f libtommath.dll libtommath.dll.a win64/
        cp -f ${prefix}/lib/libz.dll.a $WORKSPACE/srcdir/tcl/compat/zlib/win64/libz.dll.a
    elif [[ "${target}" == i686-*mingw* ]]; then
        cp -f libtommath.dll libtommath.dll.a win32/
        cp -f ${prefix}/lib/libz.dll.a $WORKSPACE/srcdir/tcl/compat/zlib/win32/zdll.lib
    fi

    cd $WORKSPACE/srcdir/tcl/win/
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} "${FLAGS[@]}"

    # Disable the zlib1.dll copy target; we use libz.dll from Zlib_jll instead.
    sed -i 's/^ZLIB_DLL_FILE.*/ZLIB_DLL_FILE =/' Makefile

    make -j${nproc}
    make install
    make install-private-headers

    # Remove leftover zlib files; Zlib_jll provides libz.dll at runtime.
    rm -f ${bindir}/zlib1.dll ${prefix}/lib/libz.dll.a
else
    cd $WORKSPACE/srcdir/tcl/unix/
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} "${FLAGS[@]}"
    make -j${nproc}
    make install
    # Tk needs private headers
    make install-private-headers
fi

# Install license file
install_license $WORKSPACE/srcdir/tcl/license.terms
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libtcl9.0", "libtcl9", "tcl90"], :libtcl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"; compat="1.2.12"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               preferred_gcc_version=v"5", julia_compat="1.6")
