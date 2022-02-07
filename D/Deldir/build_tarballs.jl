# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Deldir"
version = v"1.0.5"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://cran.r-project.org/src/contrib/Archive/deldir/deldir_$(version.major).$(version.minor)-$(version.patch).tar.gz", "a0f92dad53814744cdb8386ad2e68831d9e0287c5bc65adf0f84a77e21bc1458")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/deldir/src

for f in *.f; do 
    ${FC} -fPIC -O2 -pipe -g -c "${f}" -o "$(basename "${f}" .f).o"
done

mkdir -p "${libdir}"
${CC} -shared -o ${libdir}/libdeldir.${dlext} *.o

install_license /usr/share/licenses/GPL3
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libdeldir", :libdeldir)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
