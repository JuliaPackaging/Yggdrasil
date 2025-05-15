# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "diffutils"
version_string = "3.12"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "https://ftp.gnu.org/gnu/diffutils/diffutils-$(version_string).tar.xz",
        "7c8b7f9fc8609141fdea9cece85249d308624391ff61dedaf528fcb337727dfd",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/diffutils-*

# The autoconf test for `strcasecmp` runs code and thus doesn't work
# when cross-building. We assume that `strcasecmp` is working
# correctly.
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-dependency-tracking gl_cv_func_strcasecmp_works=yes

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("cmp", :_cmp)
    ExecutableProduct("diff", :_diff)
    ExecutableProduct("diff3", :diff3)
    ExecutableProduct("sdiff", :sdiff)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
