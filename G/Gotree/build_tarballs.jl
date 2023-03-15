using BinaryBuilder, Pkg

name = "Gotree"
version = v"0.4.2"
hash = "24bf544c9bde1c125968dd35a5bf63df9ad6b4ce"

# Collection of sources required to build pprof
sources = [
    GitSource("https://github.com/evolbioinfo/gotree.git", hash),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gotree/

VERSION_PACKAGE=github.com/evolbioinfo/gotree/cmd.Version
NAME=${bindir}/gotree${exeext}

mkdir -p ${bindir}
go build -o ${NAME} -ldflags "-X ${VERSION_PACKAGE}=${version}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("gotree", :gotree),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :go], julia_compat="1.6")
