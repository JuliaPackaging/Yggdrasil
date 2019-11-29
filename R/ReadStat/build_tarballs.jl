# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "ReadStat"
version = v"1.1.1"

sources = [
    "https://github.com/WizardMac/ReadStat.git" =>
    "51f743d0d31a761d1739865f56e0978178e7a6a8",
]

# Previously the ./configure line was
# # if [ $target = "x86_64-w64-mingw32" ] || [ $target = "i686-w64-mingw32" ]; then ./configure --prefix=${prefix} --host=${target} CFLAGS="-I$prefix/include" LDFLAGS="-L$prefix/lib"; else ./configure --prefix=${prefix} --host=${target}; fi

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ReadStat/
./autogen.sh
./configure
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("readstat", :readstat),
    LibraryProduct("libreadstat", :libreadstat),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Libiconv_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
