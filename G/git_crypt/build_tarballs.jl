# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "git_crypt"
version = v"0.6.0"

# Collection of sources required to complete build
sources = [
    "https://github.com/AGWA/git-crypt/archive/$(version).tar.gz" =>
    "777c0c7aadbbc758b69aff1339ca61697011ef7b92f1d1ee9518a8ee7702bb78",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/git-crypt-*/
make CPPFLAGS="-I${prefix}/include" LDFLAGS="-L${libdir} -lcrypto"
make install PREFIX=$prefix
if [ $target = "x86_64-w64-mingw32" ] || [ $target = "i686-w64-mingw32" ]; then
    mv $bindir/git-crypt $bindir/git-crypt.exe
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("git-crypt", :git_crypt)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "OpenSSL_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7")
