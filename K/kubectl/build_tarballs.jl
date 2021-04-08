using BinaryBuilder

name = "kubectl"
version = v"1.20.4"

# Collection of sources required to complete build
#
# Take note that different Kubernetes versions require minimum versions of Go:
# https://github.com/kubernetes/community/blob/master/contributors/devel/development.md#go
sources = [
    ArchiveSource(
        "https://github.com/kubernetes/kubernetes/archive/refs/tags/v$(version).tar.gz",
        "3fe491b90f60b1b8989556325abad53409568b96e271b00e5d23fde18f3dbe44",
    ),
]

# Bash recipe for building across all platforms
#
# Build instructions adapted from:
# - https://github.com/kubernetes/kubernetes/#to-start-developing-k8s
# - https://github.com/kubernetes/community/blob/master/contributors/devel/development.md#building-kubernetes
script = raw"""
mkdir -p $GOPATH/src/k8s.io
mv kubernetes-* $GOPATH/src/k8s.io/kubernetes
cd $GOPATH/src/k8s.io/kubernetes

# Revise bash process substitution as this fails in the build environment.
# Symptoms of this failure look like:
# `./hack/run-in-gopath.sh: line 34: _output/bin/prerelease-lifecycle-gen: Permission denied`
# and when running a clean build with `DBG_MAKEFILE` you can see the actual issue:
# `hack/lib/golang.sh: line 867: /dev/fd/62: No such file or directory`
sed -ri 's/<\s+<\((.*)\)/<<< $(\1)/' hack/lib/golang.sh hack/make-rules/clean.sh

# Disable `gofmt` as it isn't included in the compiler shard
sed -i 's/^gofmt/# \0/' hack/generate-bindata.sh

# Note: Using `-E DBG_MAKEFILE=1` is helpful for debugging Makefile issues
make WHAT=cmd/kubectl

install_license LICENSE
mkdir -p ${bindir}
mv _output/local/go/bin/kubectl ${bindir}/kubectl${exeext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("kubectl", :kubectl),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :go])
