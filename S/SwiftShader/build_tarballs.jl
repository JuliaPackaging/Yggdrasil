using BinaryBuilder

name = "SwiftShader"

version = v"0.0.1" # there are no official versions yet
commit = "2cc3490759bb615084aab934a559ac66a9818880" # January 12th, 2021

sources = [
    ArchiveSource("https://github.com/google/gfbuild-swiftshader/releases/download/github%2Fgoogle%2Fgfbuild-swiftshader%2F$(commit)/gfbuild-swiftshader-$(commit)-Linux_x64_Release.zip",
                  "20c0bba105e30b1e5ddfa73c69c2400a615bf2e76d124330897226d2fa512a50"; unpack_target="x86_64-linux-gnu"),
    ArchiveSource("https://github.com/google/gfbuild-swiftshader/releases/download/github%2Fgoogle%2Fgfbuild-swiftshader%2F$(commit)/gfbuild-swiftshader-$(commit)-Mac_x64_Release.zip",
                  "8078ef21ef02aa9f9bcf69ed303ed28b0cea1feb3129a9196385b5cd0b378c28"; unpack_target="x86_64-apple-darwin14"),
    ArchiveSource("https://github.com/google/gfbuild-swiftshader/releases/download/github%2Fgoogle%2Fgfbuild-swiftshader%2F$(commit)/gfbuild-swiftshader-$(commit)-Windows_x64_Release.zip",
                  "22354a01605adb3310736fc85cd1e20039bd4532f428226f8b3ea60d0f2bf853"; unpack_target="x86_64-w64-mingw32"),
]

script = raw"""
cd $WORKSPACE/srcdir
mkdir -p "${libdir}"
mv ${target}/lib/* ${libdir}/.
rm -rf ${libdir}/*version
install_license ${target}/OPEN_SOURCE_LICENSES.TXT
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),
]

products = [
    LibraryProduct(["libvulkan", "vk_swiftshader"], :libvulkan),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
