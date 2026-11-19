using BinaryBuilder

name = "playwright_core"
version = v"1.64.1"

sources = [
    ArchiveSource("https://registry.npmjs.org/playwright-core/-/playwright-core-$(version).tgz",
                  "3af03703c967c95037454f2283f709d53ce804a4776d4219d319f5bbcc2a0185"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/package
mkdir -pv ${prefix}/share/playwright-core
cp -vr . ${prefix}/share/playwright-core/
install_license LICENSE NOTICE ThirdPartyNotices.txt lib/*.LICENSE
"""

platforms = [AnyPlatform()]

products = [
    FileProduct("share/playwright-core/cli.js", :cli),
]

dependencies = [
    Dependency("NodeJS_24_jll"; compat="24.18.0"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
