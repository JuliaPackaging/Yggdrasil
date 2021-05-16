# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "flex"
version = v"2.6.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/westes/flex/releases/download/v$(version)/flex-$(version).tar.gz",
                  "e87aae032bf07c26f85ac0ed3250998c37621d95f8bd748b31f15b33c45ee995")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/flex-*
./autogen.sh
export CPPFLAGS="${CPPFLAGS} -I${includedir}"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static --enable-shared --disable-bootstrap
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;exclude=Sys.iswindows, experimental=true)

# The products that we will ensure are always built
products = [
    ExecutableProduct("flex", :flex),
    ExecutableProduct("flex++", :flexpp),
    LibraryProduct("libfl", :libfl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Gettext_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
