using BinaryBuilder

name = "Musl"
version = v"1.2.5"

# sources to build, such as mingw32, our patches, etc....
sources = [
    ArchiveSource("https://www.musl-libc.org/releases/musl-$(version).tar.gz",
                  "a9a118bbe84d8764da0ea0d28b3ab3fae8477fc7e4085d90102b8596fc7c75e4"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/musl-*

# Patches recommended on <https://musl.libc.org> for musl 1.2.5
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/iconv-1.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/iconv-2.patch

mkdir musl_build && cd musl_build

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

export LDFLAGS="${LDFLAGS} -Wl,-soname,libc.musl-$(musl_arch).so.1"
${WORKSPACE}/srcdir/musl-*/configure --prefix=/usr \
    --build=${MACHTYPE} \
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

install_license ${WORKSPACE}/srcdir/musl-*/COPYRIGHT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p->libc(p) != "musl")

# The products that we will ensure are always built
products = [
    LibraryProduct(["ld-musl-x86_64", "ld-musl-i386", "ld-musl-armhf", "ld-musl-aarch64"], :libc; dont_dlopen=true),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", skip_audit=true)
