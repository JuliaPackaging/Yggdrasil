using BinaryBuilder

# Collection of pre-build Bitwarden CLI binaries
name = "bitwarden_cli"
version = v"2025.1.3"

url_prefix = "https://github.com/bitwarden/clients/releases/download/cli-v$(version)"
sources = [
    ArchiveSource("$(url_prefix)/bw-oss-linux-$(version).zip", "d970a7f5a7072ab5c01576cb55df4422f46518e33bf1547a0958cd8823197950"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)/bw-oss-macos-$(version).zip", "695ab61467f58431556ca7539a03238a02f9f67e217f192428071ece061636d3"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)/bw-oss-windows-$(version).zip", "B0CD94029E3CFF8874325C160206385260E6327B34A9B8D48AA18D262728F82C"; unpack_target = "x86_64-w64-mingw32"),
    FileSource("https://raw.githubusercontent.com/bitwarden/clients/fb191b1121c30b4e839fd31689ace8373de6c840/LICENSE.txt", "cc76886c8b11ab18c7e6dcca04b7bf75caf6a2ccea42b1cfe98842f280b9bc00")
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
