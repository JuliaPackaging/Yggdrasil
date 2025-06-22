using BinaryBuilder

name = "xrootdgo"
version = v"0.34.1"

sources = [
    GitSource("https://github.com/go-hep/hep/",
              "09d53c4df12f4313bca3c9ab2dde77ab4e9f5742"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
install_license ${WORKSPACE}/srcdir/LICENSE
cd $WORKSPACE/srcdir/

mkdir clib
cp $WORKSPACE/srcdir/main.go clib/main.go
mkdir -p ${libdir}
go get github.com/google/uuid
CGO_ENABLED=1 go build -buildmode=c-shared -o ${libdir}/xrootdgo.${dlext} clib/main.go 
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("xrootdgo", :xrootdgo),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               compilers=[:c, :go], julia_compat="1.6", preferred_gcc_version=v"6")
