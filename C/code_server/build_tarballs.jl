using BinaryBuilder

name = "code_server"
version = v"4.99.2"

# We just repackage the official binaries, instead of trying to build via `npm` and all that jazz
sources = [
    ArchiveSource("https://github.com/coder/code-server/releases/download/v4.99.2/code-server-4.99.2-linux-amd64.tar.gz",
                  "528701df7df747ea77711c1c48e69642fb8234b36920a6412433f93691210542";
                  unpack_target="x86_64-linux-gnu"),
    ArchiveSource("https://github.com/coder/code-server/releases/download/v4.99.2/code-server-4.99.2-linux-arm64.tar.gz",
                  "63cda9e18893e1b73fb944e97e4b3d89de749d4335a38f8bfddf2052f10a4da3";
                  unpack_target="aarch64-linux-gnu"),
    ArchiveSource("https://github.com/coder/code-server/releases/download/v4.99.2/code-server-4.99.2-linux-armv7l.tar.gz",
                  "4ac1068113d968fea5c8784d94438ccb5ba580f4a2af010136e0a04c7ba87cde";
                  unpack_target="arm-linux-gnueabihf"),
    ArchiveSource("https://github.com/coder/code-server/releases/download/v4.99.2/code-server-4.99.2-macos-amd64.tar.gz",
                  "39e562d79726b0436521144d8fc0604aeca1d061d25bdb72c87f18bf41da1c0d";
                  unpack_target="x86_64-apple-darwin14"),
    ArchiveSource("https://github.com/coder/code-server/releases/download/v4.99.2/code-server-4.99.2-macos-arm64.tar.gz",
                  "4128a09fea929a509f094b0b8d44bd5613c60a193bf2b13bf0f89f377d68c2e1";
                  unpack_target="aarch64-apple-darwin20"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/${target}/code-server-*
cp -r * ${prefix}
install_license LICENSE
"""

platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"),
    Platform("armv7l", "linux"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
]

products = [
    ExecutableProduct("code-server", :code_server),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, []; julia_compat="1.6")
