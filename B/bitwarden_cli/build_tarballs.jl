using BinaryBuilder

# Collection of pre-build Bitwarden CLI binaries
name = "bitwarden_cli"
version = v"2025.1.3"

url_prefix = "https://github.com/bitwarden/clients/releases/download/cli-v$(version)"
sources = [
    ArchiveSource("$(url_prefix)/bw-linux-$(version).zip", "f1d66b1a3971cc906ea3e44f0647899c1ca0c95ca83714fcf3039c0643dcd97a"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)/bw-macos-$(version).zip", "103ee62a30284390559b5ff5ca21b77c235a43cb4e08e3c410726f873104cf42"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)/bw-windows-$(version).zip", "7ba89071061d30f94cea048289cd252cdb14b2635e9a57c0b020bf80121b16f5"; unpack_target = "x86_64-w64-mingw32"),
    FileSource("https://raw.githubusercontent.com/bitwarden/clients/refs/heads/main/LICENSE.txt", "b98fbb37db5b23bc5cfdcd16793206a5a7120a7b01f75374e5e0888376e4691c")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
mkdir -p "${bindir}"
cp ${target}/bw${exeext} ${bindir}
chmod +x ${bindir}/*
install_license LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; cxxstring_abi="cxx11"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows")
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("bw", :bw)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
