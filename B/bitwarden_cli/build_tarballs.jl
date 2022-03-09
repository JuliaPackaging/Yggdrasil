using BinaryBuilder

# Collection of pre-build Bitwarden CLI binaries
name = "bitwarden_cli"
version = v"1.17.1"

url_prefix = "https://github.com/bitwarden/cli/releases/download/v$(version)"
sources = [
    ArchiveSource("$(url_prefix)/bw-linux-$(version).zip", "4704297B438041D39774AA7B077DB72A184A50223FAAE906D2C238D14E2056E9"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)/bw-macos-$(version).zip", "9d5c5a997c73b84aeb43db4c7be93d3fa6443f83ade35a4953b0f1c6862c00c2"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)/bw-windows-$(version).zip", "38FE9F5126BC723FB3C0FC00DC15B013826030D6A9F54539B18DBB56EB6FB5EE"; unpack_target = "x86_64-w64-mingw32"),
    FileSource("https://raw.githubusercontent.com/bitwarden/cli/v$(version)/LICENSE.txt", "b98fbb37db5b23bc5cfdcd16793206a5a7120a7b01f75374e5e0888376e4691c")
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
