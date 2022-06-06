# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "unixODBC"
version = v"2.3.9"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://www.unixodbc.org/unixODBC-$(version).tar.gz",
                  "52833eac3d681c8b0c9a5a65f2ebd745b3a964f208fc748f977e44015a31b207"),
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
