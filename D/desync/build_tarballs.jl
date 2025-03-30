using BinaryBuilder

name = "desync"
version = v"0.9.6"

sources = [
    # Building `@staticfloat`'s fork until https://github.com/folbricht/desync/pull/283 is merged
    # This allows for easy piping of content into `desync`.
    GitSource("https://github.com/staticfloat/desync",
              "979d6ac3735680e60cd323bc6f70b433fb6027b4"),
]

# Bash recipe for building across all platforms
script = raw"""
install_license ${WORKSPACE}/srcdir/desync/LICENSE
cd ${WORKSPACE}/srcdir/desync/cmd/desync
go build
install -Dvm 755 "desync${exeext}" -t "${bindir}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> !Sys.isfreebsd(p), platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("desync", :desync),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               compilers=[:c, :go], julia_compat="1.6", preferred_gcc_version=v"6")
