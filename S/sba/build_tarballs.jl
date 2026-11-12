# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "sba"
version = v"1.6.0"

# Collection of sources required to build sba
sources = [
    GitSource("https://github.com/mlourakis/sba.git", "d0a29e03f1f9631d141fbba18534e41eec9f2f97"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
if [[ "${target}" == *mingw* ]]; then
  LBT="blastrampoline-5"
else
  LBT="blastrampoline"
fi

cd $WORKSPACE/srcdir/sba
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/use-isfinite.patch

mkdir -p ${libdir}
${CC} -shared -o ${libdir}/libsba.${dlext} -fPIC sba_chkjac.c sba_crsm.c sba_lapack.c sba_levmar.c sba_levmar_wrap.c -l${LBT}
mkdir -p ${includedir}
cp sba.h ${includedir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsba", :libsba),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.9")
