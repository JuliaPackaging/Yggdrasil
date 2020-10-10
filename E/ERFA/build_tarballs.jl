# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ERFA"
version = v"1.7.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/liberfa/erfa/releases/download/v1.7.1/erfa-1.7.1.tar.gz", "80239ae9ba4bf7f328f7f64baec7fc38e587058b3ef9cea9331c751de0b98783")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd erfa-1.7.1/
if [[ ${target} == i686-w64* ]] || [[ ${target} == x86_64-w64* ]]; then
    sed -i 's/LT_INIT/LT_INIT([win32-dll])/' configure.ac;
    sed -i 's/liberfa_la_LDFLAGS = -version-info \$(VI_ALL)/liberfa_la_LDFLAGS = -no-undefined -version-info $(VI_ALL)/' src/Makefile.am;
fi
autoreconf -fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("liberfa", :liberfa)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
