using BinaryBuilder

name = "VLConvert"
version = v"1.8.0"

url_prefix = "https://github.com/vega/vl-convert/releases/download/v$(version)/vl-convert"
sources = [
    ArchiveSource("$(url_prefix)-linux-aarch64.zip", "b5ac831f1898e2fbc07ce190baeb043b94f08db5fb981d345a018711933be5f5"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)-linux-x86.zip", "55155e33a7ea6a04fd36ec4b52403e752184edaa38d7208dbeaa78ff887550d9"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)-osx-64.zip", "e895eabce5d437c42161048da6b7168375751ce3ec3613f8e6f6a5a482675380"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)-osx-arm64.zip", "a818cffe345958602c7ed999f6cbe17e33a071060b2edc678f2943e4b3ab75c3"; unpack_target = "aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)-win-64.zip", "1beba91b80e2236ddf954a73cd0bb84522965a7144995be5c7fe3ca7aacd21b9"; unpack_target = "x86_64-w64-mingw32"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/${target}
unzip *.zip
install -Dvm 755 "bin/vl-convert${exeext}" -t "${bindir}"
install_license bin/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("aarch64", "linux"),
    Platform("x86_64", "linux"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("vl-convert", :vlconvert),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
