using BinaryBuilder

name = "Mingw32"
version = v"5.0.4"

# sources to build, such as mingw32, our patches, etc....
sources = [
    "https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v$(version).tar.bz2" =>
	"5527e1f6496841e2bb72f97a184fc79affdcd37972eaa9ebf7a5fd05c31ff803",
    "patches",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mingw-*/

export AS=${target}-as

# We need newer configure scripts
#update_configure_scripts

# This is where we'll install everything
sysroot=${prefix}/${target}/sys-root

# Patch mingw to build 32-bit cross compiler with GCC 7.1+ (This no longer needed with mingw 5.0.3+,
# so we let it fail, but leave it in incase we ever need to build an older mingw)
atomic_patch -p1 "$WORKSPACE/srcdir/patches/mingw_gcc710_i686.patch" || true

# Build CRT
mkdir -p $WORKSPACE/srcdir/mingw_crt_build
cd $WORKSPACE/srcdir/mingw_crt_build
MINGW_CONF_ARGS=""

# If we're building a 32-bit build of mingw, add `--disable-lib64`
if [[ "${target}" == i686-* ]]; then
	MINGW_CONF_ARGS="${MINGW_CONF_ARGS} --disable-lib64"
else
    MINGW_CONF_ARGS="${MINGW_CONF_ARGS} --disable-lib32"
fi

$WORKSPACE/srcdir/mingw-*/mingw-w64-crt/configure \
    --prefix=/ \
    --host=${target} \
    ${MINGW_CONF_ARGS}
make -j${nproc} 
make install DESTDIR=${sysroot}


# Build winpthreads
mkdir -p $WORKSPACE/srcdir/mingw_winpthreads_build
cd $WORKSPACE/srcdir/mingw_winpthreads_build
$WORKSPACE/srcdir/mingw-*/mingw-w64-libraries/winpthreads/configure \
    --prefix=/ \
    --host=${target} \
    --enable-static \
    --enable-shared

make -j${nproc}
make install DESTDIR=${sysroot}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Windows(:i686),
    Windows(:x86_64),
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libc", :libc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/staticfloat/KernelHeadersBuilder/releases/download/v4.12.0-0/build_KernelHeaders.v4.12.0.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
