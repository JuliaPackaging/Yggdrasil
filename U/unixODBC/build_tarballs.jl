# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "unixODBC"
version = v"2.3.12"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lurcher/unixODBC.git",
              "c335dbf3fa25b524e935e98cf26b96a2e13f5c81"),
    DirectorySource("./bundled"),	      
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/unixODBC*

# Don't use `clock_realtime` if it isn't available
cd DriverManager
atomic_patch -p0 ../../patches/clock_gettime.patch
cd ..
autoreconf -fiv
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-libiconv-prefix=${prefix} \
    --enable-readline
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
    Dependency("Readline_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
