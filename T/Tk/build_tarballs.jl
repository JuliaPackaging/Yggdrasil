# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
include("../../platforms/macos_sdks.jl")

name = "Tk"
version = v"9.0.3"

# Collection of sources required to build Tk
sources = [
    GitSource("https://github.com/tcltk/tk.git",
              "9bfcbfb7a406321125298dcaa5ea4c2a446e2ec1"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
if [[ "${target}" == *-mingw* ]]; then
    cd $WORKSPACE/srcdir/tk/win/
else
    cd $WORKSPACE/srcdir/tk/unix/
fi

# musl needs bsd-compat-headers for sys/queue.h
# Copy header to sysroot since cross-compiler doesn't see /usr/include
if [[ "${target}" == *-musl* ]]; then
    apk add bsd-compat-headers
    cp /usr/include/sys/queue.h /opt/${target}/${target}/sys-root/usr/include/sys/
fi

export CFLAGS="-I${prefix}/include ${CFLAGS}"

# Disable zipfs: Tk 9.0 embeds a zip archive in shared libraries which appends
# data past the Mach-O __LINKEDIT segment, breaking install_name_tool on macOS.
# The Tk library scripts are still installed as regular files in lib/tk9.0/.
FLAGS=(--enable-threads --disable-rpath --disable-zipfs)
if [[ "${target}" == x86_64-* ]] || [[ "${target}" == aarch64-* ]]; then
    FLAGS+=(--enable-64bit)
fi
if [[ "${target}" == *-apple-* ]]; then
    FLAGS+=(--with-x=no)
    FLAGS+=(--enable-aqua=yes)

    # The following patch replaces the hard-coded path of Cocoa framework
    # with the actual path on our system.
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/apple_cocoa_configure.patch"

    # Tk 9.0 uses @available() runtime checks which compile to calls to
    # ___isPlatformVersionAtLeast. The darwin14 toolchain's compiler runtime
    # doesn't provide this symbol, but it will be available at runtime on
    # the user's macOS system. Allow it to remain undefined at link time.
    export LDFLAGS="-Wl,-undefined,dynamic_lookup ${LDFLAGS}"
fi
if [[ "${target}" == *mingw* ]]; then
    FLAGS+=(--with-x=no)

    # `windres` invocations don't get the proper tk include path; just hack it in
    atomic_patch -p2 "${WORKSPACE}/srcdir/patches/win_tk_rc_include.patch"
fi
# Enable Xft for TrueType font support on X11 platforms
if [[ "${target}" == *-linux-* ]] || [[ "${target}" == *-freebsd* ]]; then
    FLAGS+=(--enable-xft)
fi
# musl libc has a working strtod, so disable the fixstrtod workaround
# that causes "multiple definition of fixstrtod" linker errors
if [[ "${target}" == *-musl* ]]; then
    export tcl_cv_strtod_buggy=ok
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} "${FLAGS[@]}"
make -j${nproc}
make install
make install-private-headers

# Install license file
install_license $WORKSPACE/srcdir/tk/license.terms
"""

# Tk 9.0.3 uses macOS 10.13+ APIs (window tabbing, dark mode)
sources, script = require_macos_sdk("10.15", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
x11_platforms = filter(p->Sys.islinux(p) || Sys.isfreebsd(p), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libtcl9tk9.0", "libtcl9tk9", "tcl9tk90"], :libtk),
    ExecutableProduct(["wish9.0", "wish90"], :wish),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"; platforms=x11_platforms),
    Dependency("Tcl_jll"; compat="~"*string(version)),
    Dependency("Xorg_libXft_jll"; platforms=x11_platforms),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               julia_compat="1.6")
