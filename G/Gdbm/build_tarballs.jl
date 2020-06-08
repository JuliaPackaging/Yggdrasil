# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Gdbm"
version = v"1.18.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("ftp://ftp.gnu.org/gnu/gdbm/gdbm-1.18.1.tar.gz", "86e613527e5dba544e73208f42b78b7c022d4fa5a6d5498bf18c8d6f745b91dc"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd gdbm-1.18.1/

if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 ../patches/gdbm-1.15-win32.patch
fi

if [[ "${target}" == powerpc64le-* ]] || [[ "${target}" == *-mingw* ]]; then
    # Install `autopoint` and other tools needed by `autoreconf`
    apk add gettext-dev
    # Rebuild the configure script to convince it to build the shared library
    autoreconf -vi
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static --with-libiconv-prefix=${prefix}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libgdbm", :libgdbm),
    ExecutableProduct("gdbm_load", :gdbm_load),
    ExecutableProduct("gdbmtool", :gdbmtool),
    ExecutableProduct("gdbm_dump", :gdbm_dump)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Libiconv_jll", uuid="94ce4f54-9a6c-5748-9c1c-f9c7231a4531"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
