using BinaryBuilder

name = "gawk"
version = v"5.3.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/gawk/gawk-$(version).tar.xz",
                  "694db764812a6236423d4ff40ceb7b6c4c441301b72ad502bb5c27e00cd56f78")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gawk*/

CONFIGURE_ARGS=()
if [[ ${target} == aarch64-apple-darwin* ]]; then
    # See https://git.savannah.gnu.org/cgit/gawk.git/tree/README_d/README.macosx?h=gawk-5.2.1#n1
    CONFIGURE_ARGS+=( --disable-pma )
fi

./configure --prefix=${prefix} --host=${target} ${CONFIGURE_ARGS[@]}
make -j${nproc}
make install
install_license COPYING
"""

# Windows currently fails due to a problem with mingw headers (langinfo.h) not being found
platforms = filter(!Sys.iswindows, supported_platforms())
products = [
    ExecutableProduct("gawk", :gawk)
]
dependencies = Dependency[]
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
