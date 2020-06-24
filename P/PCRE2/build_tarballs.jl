# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PCRE2"
version = v"10.34.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.pcre.org/pub/pcre/pcre2-$(version.major).$(version.minor).tar.gz",
                  "da6aba7ba2509e918e41f4f744a59fa41a2425c59a298a232e7fe85691e00379")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pcre2-*/

# Update configure scripts
update_configure_scripts

# Force optimization
export CFLAGS="${CFLAGS} -O3"

./configure --prefix=${prefix} --host=${target} \
    --disable-static \
    --enable-jit \
    --enable-pcre2-16 \
    --enable-pcre2-32

make -j${nproc}
make install

# On windows we need libcpre2-8.dll as well
if [[ ${target} == *mingw* ]]; then
    ln -s libpcre2-8-0.dll  ${libdir}/libpcre2-8.dll
    ln -s libpcre2-16-0.dll ${libdir}/libpcre2-16.dll
    ln -s libpcre2-32-0.dll ${libdir}/libpcre2-32.dll
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libpcre2-8", :libpcre2_8),
    LibraryProduct("libpcre2-16", :libpcre2_16),
    LibraryProduct("libpcre2-32", :libpcre2_32)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
