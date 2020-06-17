using BinaryBuilder, Pkg

name = "GLPK"
version = v"4.64"

# Collection of sources required to build GLPKBuilder
sources = [
    ArchiveSource("http://ftpmirror.gnu.org/gnu/glpk/glpk-$(version.major).$(version.minor).tar.gz",
                  "539267f40ea3e09c3b76a31c8747f559e8a097ec0cda8f1a3778eec3e4c3cc24"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/glpk*
if [[ ${target} == *mingw* ]]; then
    export CPPFLAGS="-I${prefix}/include -D__WOE__=1";
else
    export CPPFLAGS="-I${prefix}/include";
fi
autoreconf -vi
./configure --prefix=${prefix} --host=${target} --build=${MACHTYPE} --with-gmp
make -j${nproc}
make install
"""

# Build for all platforms
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libglpk", :libglpk)
]

GMP_packagespec = PackageSpec(; name = "GMP_jll",
                              uuid = "781609d7-10c4-51f6-84f2-b8444358ff6d",
                              version = v"6.1.2")

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(GMP_packagespec)
]

# Build the tarballs, and possibly a `build.jl` as well.
# Use the same preferred_gcc_version as GMP.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
