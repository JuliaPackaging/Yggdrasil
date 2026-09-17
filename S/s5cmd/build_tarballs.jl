using BinaryBuilder

name = "s5cmd"
version = v"2.3.0"

# Collection of sources required to build s5cmd
sources = [
    GitSource("https://github.com/peak/s5cmd.git",
              "991c9fbc16709341b4bac04513232a1445941f63"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/s5cmd/
install_license LICENSE

mkdir -p ${bindir}

# the Makefile redefines compiler env vars, so we roll our own invocation
go build -o ${bindir} -mod=vendor \
         -ldflags "-X=github.com/peak/s5cmd/v2/version.Version=2.3.0 -X=github.com/peak/s5cmd/v2/version.GitCommit=991c9fbc16709341b4bac04513232a1445941f63"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("s5cmd", :s5cmd),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               compilers=[:c, :go], julia_compat = "1.6")
