using BinaryBuilder

name    = "Git_LFS"
version = v"3.8.1"

sources = [
    GitSource("https://github.com/git-lfs/git-lfs.git", "a662a6dbfedf706cfa9fc7a5b7bcc7ba2e2c8a65"; tag="v$(version)")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/git-lfs/
mkdir -p ${bindir}

# The go.mod `go` directive (1.25.0) otherwise selects a toolchain whose stdlib
# has known vulnerabilities; pin a patched release instead.
export GOTOOLCHAIN=go1.26.8

# git-lfs v3.8.1 pins golang.org/x/crypto v0.54.0, affected by CVE-2026-56854.
go get golang.org/x/crypto@v0.55.0
go mod tidy

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
