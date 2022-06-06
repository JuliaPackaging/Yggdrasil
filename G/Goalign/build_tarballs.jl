using BinaryBuilder, Pkg

name = "Goalign"
version = v"0.3.5"
hash = "9593e5fba495e67b4c15aeee53fd292547518c2c"

# Collection of sources required to build pprof
sources = [
    GitSource("https://github.com/evolbioinfo/goalign.git", hash),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/goalign/

VERSION_PACKAGE=github.com/evolbioinfo/goalign/version.Version
NAME=${bindir}/goalign${exeext}

mkdir -p ${bindir}
go build -o ${NAME} -ldflags "-X ${VERSION_PACKAGE}=${version}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("goalign", :goalign),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :go], julia_compat="1.6")
