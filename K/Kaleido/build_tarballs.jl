using BinaryBuilder

name = "Kaleido"
version = v"0.1.0"

url_prefix = "https://github.com/plotly/Kaleido/releases/download/v$(version)/kaleido"
sources = [
    ArchiveSource("$(url_prefix)_linux_x64.zip", "6214b5e3082f315ead32133d13c3aacd385d1dab0da8eca9c6a6febf1669e9c8"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)_linux_arm64.zip", "a66d0ad6da9edb0ea00508c2eaf79b386f6f22cb67b40812537a8aa05ac2e746"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)_mac.zip", "4a583ee9363a9feed3ed6b7308ffeb1f11e8da57a978583bb7e9b4591dc55e38"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)_win_x64.zip", "58b57a973e660a4e7395e595a277492aa9008e0a25c3446656a52f7652b5f8a6"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)_win_x86.zip", "aa87ac1957e84f4f66f70de1c2dd9a2355ef7737cdf16b3e4125350836fe0484"; unpack_target = "i686-w64-mingw32"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
cp -r ${target}/* ${prefix}/.
chmod +x ${bindir}/*
if [[ "${target}" == *-mingw* ]]; then
    chmod +x ${prefix}/kaleido.cmd
fi
if [[ "${target}" != *-apple-darwin* ]]; then
    chmod +x ${bindir}/swiftshader/*.${dlext}
fi
LIC_DIR="${prefix}/share/licenses/${SRC_NAME}"
mkdir -p "${LIC_DIR}"
mv "${prefix}/LICENSE.txt" "${LIC_DIR}/LICENSE.txt"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"),
    Platform("x86_64", "macos"),
    Platform("i686", "windows"),
    Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("kaleido", :kaleido),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
