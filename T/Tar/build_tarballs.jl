# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Tar"
version = v"1.35"

# Collection of sources required to build tar
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/tar/tar-$(version.major).$(version.minor).tar.xz",
                  "4d62ff37342ec7aed748535323930c7cf94acf71c3591882b26a7ea50f3edc16"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tar-*/
export FORCE_UNSAFE_CONFIGURE=1
configure_flags=()
if [[ ${nbits} == 32 ]]; then
   # We disable the year 2038 check because we don't have an alternative on the affected systems
   configure_flags+=(--disable-year2038)
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} ${configure_flags[@]}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = filter!(!Sys.iswindows, supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    ExecutableProduct("tar", :tar),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Attr_jll"),
    Dependency("Libiconv_jll", platforms=filter(Sys.isapple, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
