# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "git_crypt"
version = v"0.7.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/AGWA/git-crypt.git",
              "a1e6311f5622fb6b9027fc087d16062c7261280f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/git-crypt
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
    Dependency("OpenSSL_jll"; compat="1.1.10"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7", julia_compat="1.6")
