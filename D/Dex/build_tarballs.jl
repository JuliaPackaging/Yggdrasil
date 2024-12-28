# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Dex"
version = v"2.41.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/dexidp/dex.git", "43956db7fd75c488a82c70cf231f44287300a75d"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir -p "${bindir}" "${prefix}/share"
cd dex/
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
install_license LICENSE
go get -u entgo.io/contrib/entproto@latest
go get entgo.io/contrib/entproto/cmd/protoc-gen-entgrpc@latest
go mod tidy
make build
mkdir -p $bindir
mv bin/dex "$bindir/dex${exeext}"
tar -czvf $prefix/share/webtemplates.tar.gz -C ./web static templates themes
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="glibc")
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("dex", :dex),
    FileProduct("share/webtemplates.tar.gz", :webtemplates),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers = [:go, :c])
