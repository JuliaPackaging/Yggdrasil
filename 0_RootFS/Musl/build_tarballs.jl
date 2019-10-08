using BinaryBuilder

name = "Musl"
version = v"1.1.22"

# sources to build, such as mingw32, our patches, etc....
sources = [
    "https://www.musl-libc.org/releases/musl-$(version).tar.gz" =>
    "8b0941a48d2f980fd7036cfbd24aa1d414f03d9a0652ecbd5ec5c7ff1bee29e3",
]

# Bash recipe for building across all platforms
script = raw"""
mkdir ${WORKSPACE}/srcdir/musl_build
cd ${WORKSPACE}/srcdir/musl_build
musl_arch()                                                                                                                                                                                             
{
    case "${target}" in
        i686*)
            echo i386 ;;
        arm*)
            echo armhf ;;
        *)
            echo ${target%%-*} ;;
    esac
}

export LDFLAGS="${LDFLAGS} -Wl,-soname,libc.musl-$(musl_target).so.1"
${WORKSPACE}/srcdir/musl-*/configure --prefix=/usr \
    --host=${target} \
    --disable-multilib \
    --disable-werror \
    --enable-optimize \
    --enable-debug

make -j${nproc}

# Install to fake directory
make install DESTDIR=${WORKSPACE}/srcdir/musl_deploy

# In reality, all we want is what we need to run Musl programs, so
# we just copy the dynamic loader directly over.
mkdir -p ${prefix}/lib
loader=$(echo ${WORKSPACE}/srcdir/musl_deploy/lib/*.so*)
mv ${WORKSPACE}/srcdir/musl_deploy/usr/lib/libc.so ${prefix}/lib/$(basename "${loader}")
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:musl)
    Linux(:i686, libc=:musl)
    Linux(:aarch64, libc=:musl)
    Linux(:armv7l, libc=:musl)
]

# The products that we will ensure are always built
products = [
    LibraryProduct(["ld-musl-x86_64", "ld-musl-i386", "ld-musl-armhf", "ld-musl-aarch64"], :libc; dont_dlopen=true),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, skip_audit=true)
