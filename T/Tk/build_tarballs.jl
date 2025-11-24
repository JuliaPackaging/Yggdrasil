# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Tk"
version = v"8.6.12"

# Collection of sources required to build Tk
sources = [
    ArchiveSource("https://downloads.sourceforge.net/sourceforge/tcl/tk$(version)-src.tar.gz",
                  "12395c1f3fcb6bed2938689f797ea3cdf41ed5cb6c4766eec8ac949560310630"),
    DirectorySource("./bundled"),
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
if [[ "${target}" == x86_64-* ]] || [[ "${target}" == aarch64-* ]]; then
    FLAGS+=(--enable-64bit)
fi
if [[ "${target}" == *-apple-* ]]; then
    FLAGS+=(--with-x=no)
    FLAGS+=(--enable-aqua=yes)

    # The following patch replaces the hard-coded path of Cocoa framework
    # with the actual path on our system.
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/apple_cocoa_configure.patch"
fi
if [[ "${target}" == *mingw* ]]; then
    FLAGS+=(--with-x=no)

    # `windres` invocations don't get the proper tk include path; just hack it in
    atomic_patch -p2 "${WORKSPACE}/srcdir/patches/win_tk_rc_include.patch"
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} "${FLAGS[@]}"
make -j${nproc}
make install
make install-private-headers

# Install license file
install_license $WORKSPACE/srcdir/tk*/license.terms
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
x11_platforms = filter(p->Sys.islinux(p) || Sys.isfreebsd(p), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libtk8.6", "libtk8", "tk86"], :libtk),
    ExecutableProduct(["wish8.6", "wish86"], :wish),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"; platforms=x11_platforms),
    Dependency("Tcl_jll"; compat="~"*string(version)),
    Dependency("Xorg_libXft_jll"; platforms=x11_platforms)
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               julia_compat="1.6")
