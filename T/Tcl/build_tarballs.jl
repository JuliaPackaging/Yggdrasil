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
    cd $WORKSPACE/srcdir/tcl/win/
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
make -j${nproc}
make install
# Tk needs private headers
make install-private-headers

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
               julia_compat="1.6", preferred_gcc_version=v"5")
