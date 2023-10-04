# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "wget"
version = v"1.21.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/wget/wget-$(version).tar.gz",
                  "81542f5cefb8faacc39bbbc6c82ded80e3e4a88505ae72ea51df27525bcde04c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wget-*/

FLAGS=()
if [[ "${target}" == *-darwin* ]]; then
    # https://lists.gnu.org/archive/html/bug-wget/2021-01/msg00076.html
    FLAGS+=(--without-included-regex)
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} "${FLAGS[@]}"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Disable windows because GnuTLS_jll is not available there
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("wget", :wget)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GnuTLS_jll"),
    Dependency("Nettle_jll", v"3.7.2"; compat="~3.7.2"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
