using BinaryBuilder


name = "licensecheck"
version = v"0.3.1"

sources = [
    GitSource("https://github.com/google/licensecheck",
              "16aaea36649f556bae5a5ee972c247f58a0de1c4"),
    DirectorySource("./bundled")

]

# Bash recipe for building across all platforms
script = raw"""
install_license ${WORKSPACE}/srcdir/licensecheck/LICENSE
cd $WORKSPACE/srcdir/licensecheck/
mkdir clib
cp $WORKSPACE/srcdir/main.go clib/main.go
mkdir -p ${libdir}
CGO_ENABLED=1 go build -buildmode=c-shared -o ${libdir}/licensecheck.${dlext} clib/main.go 
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("licensecheck", :licensecheck),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :go], preferred_gcc_version=v"6")
