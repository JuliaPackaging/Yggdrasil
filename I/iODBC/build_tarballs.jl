# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "iODBC"
version = v"3.52.16"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/openlink/iODBC.git",
              "79c7f572a7b5c4123ec3cc1dd29df1af61a3405f"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/iODBC/
atomic_patch -p1 ../patches/do-not-strip.patch
./autogen.sh 
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libiodbcinst", :libiodbcinst),
    ExecutableProduct("iodbctestw", :iodbctestw),
    LibraryProduct("libiodbc", :libiodbc),
    ExecutableProduct("iodbctest", :iodbctest)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
