# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libuuid"
version_string = "2.40.2"
version = VersionNumber(version_string)

# Collection of sources required to build Libuuid
sources = [
    ArchiveSource("https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v$(version.major).$(version.minor)/util-linux-$(version_string).tar.xz",
                  "d78b37a66f5922d70edf3bdfb01a6b33d34ed3c3cafd6628203b2a2b67c8e8b3"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/util-linux-*

configure_flags=()
if [[ ${nbits} == 32 ]]; then
   # We disable the year 2038 check because we don't have an alternative on the affected systems
   configure_flags+=(--disable-year2038)
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-all-programs --enable-libuuid ${configure_flags[@]}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(!Sys.iswindows, platforms)
# This package on macOS creates more problems than it solves:
# <https://github.com/JuliaPackaging/Yggdrasil/issues/8256>.
filter!(!Sys.isapple, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libuuid", :libuuid),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
