# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "MozillaCACerts"
# Info and new versions here: https://curl.haxx.se/docs/caextract.html
cacert_version = "2024-11-26"
version = VersionNumber(replace(cacert_version, '-'=>'.'))

# Collection of sources required to build MozillaCACerts
sources = [
    FileSource("https://curl.haxx.se/ca/cacert-$cacert_version.pem", 
               "bb1782d281fe60d4a2dcf41bc229abe3e46c280212597d4abcc25bddf667739b",
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
