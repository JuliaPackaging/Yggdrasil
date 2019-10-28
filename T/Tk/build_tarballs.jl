# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Tk"
version = v"8.6.9" # current version number is actually 8.6.9.1

# Collection of sources required to build Tk
sources = [
    "https://downloads.sourceforge.net/sourceforge/tcl/tk$(version).1-src.tar.gz" =>
    "8fcbcd958a8fd727e279f4cac00971eee2ce271dc741650b1fc33375fb74ebb4",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
if [[ "${target}" == *-mingw* ]]; then
    cd $WORKSPACE/srcdir/tk*/win/
else
    cd $WORKSPACE/srcdir/tk*/unix/
fi

export CFLAGS="-I${prefix}/include ${CFLAGS}"

FLAGS=(--enable-threads --disable-rpath)
if [[ "${target}" == x86_64-* ]]; then
    FLAGS+=(--enable-64bit)
fi
if [[ "${target}" == *-apple-* ]] || [[ "${target}" == -*mingw* ]]; then
    FLAGS+=(--with-x=no)
fi
if [[ "${target}" == *-apple-* ]]; then
    FLAGS+=(--enable-aqua=yes)

    # The following patch replaces the hard-coded path of Cocoa framework
    # with the actual path on our system.
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/apple_cocoa_configure.patch"
fi
if [[ "${target}" == *mingw* ]]; then
    # `windres` invocations don't get the proper tk include path; just hack it in
    atomic_patch -p2 "${WORKSPACE}/srcdir/patches/win_tk_rc_include.patch"
fi

./configure --prefix=${prefix} --host=${target} "${FLAGS[@]}"
make -j${nproc}
make install
make install-private-headers

# Install license file
install_license $WORKSPACE/srcdir/tk*/license.terms
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libtk8.6", "libtk8", "tk86"], :libtk),
    ExecutableProduct(["wish8.6", "wish86"], :wish),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Tcl_jll",
    "Xorg_libXft_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
