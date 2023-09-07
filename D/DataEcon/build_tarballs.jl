# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "DataEcon"
version = v"0.2.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/bankofcanada/DataEcon.git",
        "8c37f65f803c7fc5d3c5df961c4bdefdfcd7ff3a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/DataEcon/
make -j${nproc} all LIBDE="bin/libdaec.${dlext}"
install_license LICENSE.md
install -Dvm 755 "bin/sqlite3${exeext}" "${bindir}/sqlite3${exeext}"
install -Dvm 755 "bin/libdaec.${dlext}" "${libdir}/libdaec.${dlext}"
install -Dvm 644 src/daec.h "${includedir}/daec.h"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct(["libdaec", "daec"], :libdaec),
    ExecutableProduct("sqlite3", :sqlite3shell),
    FileProduct("include/daec.h", :daec_header),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"10.2.0")
