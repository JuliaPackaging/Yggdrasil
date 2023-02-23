using BinaryBuilder

name = "Kaleido"
version = v"0.2.1"

url_prefix = "https://github.com/plotly/Kaleido/releases/download/v$(version)/kaleido"
sources = [
    ArchiveSource("$(url_prefix)_linux_x64.zip", "3eaa3efd41a00db05dd71add7f54ad4e9d4259552e3f7470ac4c1a8594cea214"; unpack_target = "x86_64-linux-gnu"),
    ArchiveSource("$(url_prefix)_linux_arm64.zip", "a6040fa4d95692b7047d3880391f539ea7af9353b0c7b0558ea7b8e280013703"; unpack_target = "aarch64-linux-gnu"),
    ArchiveSource("$(url_prefix)_mac_x64.zip", "57e3e1a1d98f1c25f565a1d37cbc2baf0509c13e37e6b92f7d3cb89c53b28f27"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("$(url_prefix)_mac_arm64.zip", "e5cc7bceb096db135384928d1f11b115c5697dcd1f66e7064ddb91562a61d55f"; unpack_target = "aarch64-apple-darwin20"),
    ArchiveSource("$(url_prefix)_win_x64.zip", "22857d6696fe348fea166b2950263e8c2fa41e465a1a354f2e09a6f90dfe6df3"; unpack_target = "x86_64-w64-mingw32"),
    ArchiveSource("$(url_prefix)_win_x86.zip", "771d0372e003393a313adb38a6a3fed3eaf9a9ad46b1453f92cb5489efcee376"; unpack_target = "i686-w64-mingw32"),
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
    Platform("aarch64", "macos"),
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
