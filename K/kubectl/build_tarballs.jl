using BinaryBuilder

name = "kubectl"
version = v"1.20.7"

# Collection of sources required to complete build
#
# Take note that different Kubernetes versions require minimum versions of Go:
# https://github.com/kubernetes/community/blob/master/contributors/devel/development.md#go
sources = [
    ArchiveSource(
        "https://github.com/kubernetes/kubernetes/archive/refs/tags/v$(version).tar.gz",
        "3e4e698e142dbbdc6a5c84b140eb20477a4e0da1903395d59de84d0d254ae7fd",
    ),
]

# Bash recipe for building across all platforms
#
# Build instructions adapted from:
# - https://github.com/kubernetes/kubernetes/#to-start-developing-k8s
# - https://github.com/kubernetes/community/blob/master/contributors/devel/development.md#building-kubernetes
script = raw"""
# Use the larger WORKSPACE volume for tmp to avoid: "No space left on device"
export TMPDIR=${WORKSPACE}/tmp
mkdir -p $TMPDIR

# Switch to using the host toolchain so Kubernetes can generate some build tools
go_cross=$([ "$(go env GOHOSTOS)/$(go env GOHOSTARCH)" = "$(go env GOOS)/$(go env GOARCH)" ]; echo $? )
if [ $go_cross -eq 1 ]; then
    cd /opt/bin/x86_64-linux-musl-*/
    for f in x86_64-linux-musl-*; do
        ln -s "$f" "${f//x86_64-linux-musl-/}"
    done
    ORG_PATH="$PATH"
    export PATH="$(pwd):$PATH"
    cd -
fi

mkdir -p $GOPATH/src/k8s.io
mv kubernetes-* $GOPATH/src/k8s.io/kubernetes
cd $GOPATH/src/k8s.io/kubernetes

# Revise bash process substitution as this fails in the build environment.
# Symptoms of this failure look like:
# `./hack/run-in-gopath.sh: line 34: _output/bin/prerelease-lifecycle-gen: Permission denied`
# and when running a clean build with `DBG_MAKEFILE` you can see the actual issue:
# `hack/lib/golang.sh: line 867: /dev/fd/62: No such file or directory`
sed -ri 's/<\s+<\(/<<< \$(/' hack/lib/golang.sh hack/make-rules/clean.sh

# Need to avoid using `GOBIN` to allow for cross-compilation.
# ```
# go install: cannot install cross-compiled binaries when GOBIN is set
# make[1]: *** [Makefile.generated_files:627: gen_bindata] Error 1
# ```
sed -ri 's/^export GOBIN|^PATH/# \0/' hack/generate-bindata.sh

if [ $go_cross -eq 1 ]; then
    # Build for the host first to generate some tools need to be run on the host
    make WHAT=cmd/kubectl KUBE_BUILD_PLATFORMS=$(go env GOHOSTOS)/$(go env GOHOSTARCH)

    # Restore the target toolchain
    export PATH=$ORG_PATH
fi

# Note: Using `-E DBG_MAKEFILE=1` is helpful for debugging Makefile issues
make WHAT=cmd/kubectl KUBE_BUILD_PLATFORMS=$(go env GOOS)/$(go env GOARCH)

install_license LICENSE
mkdir -p ${bindir}

if [ $go_cross -eq 1 ]; then
    output_dir="_output/local/go/bin/$(go env GOOS)_$(go env GOARCH)"
else
    output_dir="_output/local/bin/$(go env GOOS)/$(go env GOARCH)"
fi

mv ${output_dir}/kubectl ${bindir}/kubectl${exeext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    ExecutableProduct("kubectl", :kubectl),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :go], julia_compat="1.6")
