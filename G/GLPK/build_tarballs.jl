using BinaryBuilder, Pkg

name = "GLPK"
version = v"4.65"

# Collection of sources required to build GLPKBuilder
sources = [
    ArchiveSource("http://ftpmirror.gnu.org/gnu/glpk/glpk-$(version.major).$(version.minor).tar.gz",
                  "4281e29b628864dfe48d393a7bedd781e5b475387c20d8b0158f329994721a10"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/glpk*
if [[ ${target} == *mingw* ]]; then
    export CPPFLAGS="-I${prefix}/include -D__WOE__=1";
else
    export CPPFLAGS="-I${prefix}/include";
fi
./configure --prefix=${prefix} --host=${target} --build=${MACHTYPE} --with-gmp
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = [p for p in platforms if !(typeof(p) <: FreeBSD)]
platforms = [p for p in platforms if !(arch(p) == :powerpc64le)]
                        
# The products that we will ensure are always built
products = [
    LibraryProduct("libglpk", :libglpk)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
