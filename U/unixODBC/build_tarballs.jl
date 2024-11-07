# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "unixODBC"
version = v"2.3.12"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://www.unixodbc.org/unixODBC-$(version).tar.gz",
                  "f210501445ce21bf607ba51ef8c125e10e22dffdffec377646462df5f01915ec"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/unixODBC-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-libiconv-prefix=${prefix}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libodbc", :libodbc),
    ExecutableProduct("odbc_config", :odbc_config),
    LibraryProduct("libodbcinst", :libodbcinst),
    ExecutableProduct("isql", :isql),
    ExecutableProduct("iusql", :iusql),
    ExecutableProduct("odbcinst", :odbcinst),
    LibraryProduct("libodbccr", :libodbccr),
    ExecutableProduct("slencheck", :slencheck),
    ExecutableProduct("dltest", :dltest)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libiconv_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
