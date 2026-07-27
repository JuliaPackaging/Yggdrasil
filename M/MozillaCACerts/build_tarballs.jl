# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "MozillaCACerts"
# Info and new versions here: https://curl.haxx.se/docs/caextract.html
cacert_version = "2026-07-16"
version = VersionNumber(replace(cacert_version, '-'=>'.'))

# Collection of sources required to build MozillaCACerts
sources = [
    FileSource("https://curl.haxx.se/ca/cacert-$cacert_version.pem", 
               "3ff344e30b9b1ed2971044eabb438a08f2e2245ddb5f8ab1a3ad8b63ab4eaf91",
               filename="cacert.pem"),
]

# Bash recipe for building across all platforms
script = raw"""
install -Dvm 0644 "${WORKSPACE}/srcdir/cacert.pem" "${prefix}/share/cacert.pem"
install_license /usr/share/licenses/MPL2
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    FileProduct("share/cacert.pem", :cacert)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
