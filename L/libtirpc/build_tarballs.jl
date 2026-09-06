# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libtirpc"
version = v"1.3.7"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://downloads.sourceforge.net/project/libtirpc/libtirpc/$(version)/libtirpc-$(version).tar.bz2", "b47d3ac19d3549e54a05d0019a6c400674da716123858cfdb6d3bdd70a66c702"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libtirpc-*/

install_license COPYING

#musl does not have this header, so we manually carry it around, queue.h file contents taken from https://github.com/dbmail/dbmail/blob/master/compatibility/queue.h
if [[ ${target} == *-musl* ]]; then
    mkdir sys
    cp $WORKSPACE/srcdir/queue.h $WORKSPACE/srcdir/libtirpc-*/sys/
fi

./configure \
--prefix=${prefix} \
--build=${MACHTYPE} \
--host=${target} \
--enable-static=no \
--enable-shared=yes \
--disable-gssapi

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental = true)
#this is really only supported for linux platforms
filter!(Sys.islinux, platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libtirpc", :libtirpc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
