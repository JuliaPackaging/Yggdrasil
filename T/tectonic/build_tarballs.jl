using BinaryBuilder

name = "tectonic"
version = v"0.7.1"

url_prefix = "https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%40$(version)/tectonic-$(version)"
sources = [
    ArchiveSource("$(url_prefix)-x86_64-unknown-linux-gnu.tar.gz", "3a128a4f2302033c350f9a18dc35a48f3034173d9e02b80c00ae4f83ee506cde"; unpack_target="x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-x86_64-unknown-linux-musl.tar.gz", "e46767ab9edc8cd83666a293020c290c984470d984f6f6e2f53454c0869c3dd4"; unpack_target="x86_64-linux-musl"),
    FileSource("https://raw.githubusercontent.com/tectonic-typesetting/tectonic/tectonic%40$(version)/LICENSE", "814a258f76e420b25cb3c07172eb2b3956f34cefbf0a650413b78e65c425f306"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
mkdir -p "${bindir}"
dirprefix="${target}/"
install -m 755 "${dirprefix}tectonic${exeext}" "${bindir}/tectonic${exeext}"
install_license LICENSE
"""

platforms = [
    Platform("x86_64", "linux"),
    Platform("x86_64", "linux"; libc="musl"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("tectonic", :tectonic),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
