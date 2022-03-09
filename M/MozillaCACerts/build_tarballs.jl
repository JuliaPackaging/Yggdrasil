# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "MozillaCACerts"
# Info and new versions here: https://curl.haxx.se/docs/caextract.html
cacert_version = "2022-02-01"
version = VersionNumber(replace(cacert_version, '-'=>'.'))

# Collection of sources required to build MozillaCACerts
sources = [
    FileSource("https://curl.haxx.se/ca/cacert-$cacert_version.pem", 
               "1d9195b76d2ea25c2b5ae9bee52d05075244d78fcd9c58ee0b6fac47d395a5eb",
               filename="cacert.pem"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/
mkdir -p $prefix/share
cp cacert.pem $prefix/share/cacert.pem
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    FileProduct("share/cacert.pem", :cacert)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
