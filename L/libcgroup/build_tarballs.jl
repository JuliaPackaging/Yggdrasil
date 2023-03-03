# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libcgroup"
version = v"3.0"

# Collection of sources required to build libcgroup
sources = [
    ArchiveSource("https://github.com/libcgroup/libcgroup/releases/download/v$(version.major).$(version.minor)/libcgroup-$(version).tar.gz",
                  "8d284d896fca1c981b55850e92acd3ad9648a69227c028dda7ae3402af878edd"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd libcgroup-*
install_license COPYING

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-replace_ac_malloc_realloc.patch
autoreconf -i

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-pam
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(Sys.islinux, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcgroup", :libcgroup),
    ExecutableProduct("cgclassify", :cgclassify),
    ExecutableProduct("cgcreate", :cgcreate),
    ExecutableProduct("cgdelete", :cgdelete),
    ExecutableProduct("cgexec", :cgexec),
    ExecutableProduct("cgget", :cgget),
    ExecutableProduct("cgset", :cgset),
    ExecutableProduct("cgsnapshot", :cgsnapshot),
    ExecutableProduct("cgxget", :cgxget),
    ExecutableProduct("cgxset", :cgxset),
    ExecutableProduct("lscgroup", :lscgroup),
    ExecutableProduct("lssubsys", :lssubsys),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("fts_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
