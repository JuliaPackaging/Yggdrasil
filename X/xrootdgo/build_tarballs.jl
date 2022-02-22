using BinaryBuilder

name = "xrootdgo"
version = v"0.30.1"

sources = [
    GitSource("https://github.com/go-hep/hep/",
              "76e7c8652ee045064931dec627aedd33b4457fee"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
install_license ${WORKSPACE}/srcdir/hep/LICENSE
cd $WORKSPACE/srcdir/hep/

mkdir clib
cp $WORKSPACE/srcdir/main.go clib/main.go
mkdir -p ${libdir}
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
