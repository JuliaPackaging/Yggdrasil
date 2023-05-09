using BinaryBuilder

name = "gawk"
version = v"5.2.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/gawk/gawk-$(version).tar.xz",
                  "673553b91f9e18cc5792ed51075df8d510c9040f550a6f74e09c9add243a7e4f")
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
