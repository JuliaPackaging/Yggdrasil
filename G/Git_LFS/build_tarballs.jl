using BinaryBuilder

name    = "Git_LFS"
version = v"3.7.0"

sources = [
    GitSource("https://github.com/git-lfs/git-lfs.git", "92dddf560e62ef7dd25877d87ce072f7595aa52d")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/git-lfs/
mkdir -p ${bindir}

# Install goversioninfo if host is Windows
case "$MACHTYPE" in
  *mingw*|*cygwin*) go install github.com/josephspurrier/goversioninfo/cmd/goversioninfo ;;
esac
export PATH="$GOPATH/bin:$PATH"

go build -o ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("git-lfs", :git_lfs),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :go], julia_compat="1.6")
