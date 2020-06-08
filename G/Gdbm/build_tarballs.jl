# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Gdbm"
version = v"1.18.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("ftp://ftp.gnu.org/gnu/gdbm/gdbm-1.18.1.tar.gz", "86e613527e5dba544e73208f42b78b7c022d4fa5a6d5498bf18c8d6f745b91dc")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd gdbm-1.18.1/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static --with-libiconv-prefix=${prefix}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    FreeBSD(:x86_64)
]


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
