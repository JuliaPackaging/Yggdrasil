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
if [[ "${target}" == *-mingw* ]]; then
    # The pre-built DLLs in the Tcl source tree were compiled with MSVC (UCRT)
    # but tcl90.dll is cross-compiled with MinGW (msvcrt), causing crashes.
    # Fix: cross-compile libtommath from source, and use Zlib_jll's zlib.

    # Cross-compile libtommath from source.
    cd $WORKSPACE/srcdir/tcl/libtommath
    TOMMATH_CFLAGS="-O2 -I. -DTCL_WITH_EXTERNAL_TOMMATH"
    if [[ "${target}" == x86_64-* ]] || [[ "${target}" == aarch64-* ]]; then
        TOMMATH_CFLAGS="${TOMMATH_CFLAGS} -DMP_64BIT"
    fi
    ${CC} ${TOMMATH_CFLAGS} -shared -o libtommath.dll bn_*.c \
        -Wl,--out-implib,libtommath.dll.a

    # Replace pre-built libtommath with cross-compiled version.
    if [[ "${target}" == aarch64-*mingw* ]]; then
        cp -f libtommath.dll libtommath.dll.a win64-arm/
    elif [[ "${target}" == x86_64-*mingw* ]]; then
        cp -f libtommath.dll libtommath.dll.a win64/
    fi

    cd $WORKSPACE/srcdir/tcl/win/
    # `make install` calls `tclsh` on Windows
    apk add tcl
else
    cd $WORKSPACE/srcdir/tcl/unix/
fi

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

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} "${FLAGS[@]}"

# On Windows, the configure hardcodes ZLIB_LIBS to pre-built MSVC DLLs from
# the source tree. Use Zlib_jll's zlib instead (available on the path at runtime).
if [[ "${target}" == *-mingw* ]]; then
    sed -i 's|[^ ]*compat/zlib[^ ]*/libz\.dll\.a|-lz|g' Makefile
fi

make -j${nproc}
make install
# Tk needs private headers
make install-private-headers

# Remove the pre-built MSVC zlib1.dll that the Makefile installs;
# tcl90.dll now imports libz.dll from Zlib_jll at runtime.
if [[ "${target}" == *-mingw* ]]; then
    rm -f ${bindir}/zlib1.dll
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
