using BinaryBuilder

name = "swiftshader"

version = v"0.0.1" # there are no official versions yet
commit = "2cc3490759bb615084aab934a559ac66a9818880" # January 12th, 2021
tarball_linux = "https://github.com/google/gfbuild-swiftshader/releases/download/github%2Fgoogle%2Fgfbuild-swiftshader%2F$(commit)/gfbuild-swiftshader-$(commit)-Linux_x64_Release.zip"
tarball_macos = "https://github.com/google/gfbuild-swiftshader/releases/download/github%2Fgoogle%2Fgfbuild-swiftshader%2F$(commit)/gfbuild-swiftshader-$(commit)-Mac_x64_Release.zip"
tarball_windows = "https://github.com/google/gfbuild-swiftshader/releases/download/github%2Fgoogle%2Fgfbuild-swiftshader%2F$(commit)/gfbuild-swiftshader-$(commit)-Windows_x64_Release.zip"

src_linux = [ArchiveSource(tarball_linux, "20c0bba105e30b1e5ddfa73c69c2400a615bf2e76d124330897226d2fa512a50")]
src_macos = [ArchiveSource(tarball_macos, "8078ef21ef02aa9f9bcf69ed303ed28b0cea1feb3129a9196385b5cd0b378c28")]
src_windows = [ArchiveSource(tarball_windows, "22354a01605adb3310736fc85cd1e20039bd4532f428226f8b3ea60d0f2bf853")]

script = raw"""
cd $WORKSPACE/srcdir
mv lib ${prefix}/
rm -rf ${prefix}/lib/*version
mkdir -p ${prefix}/share/licenses/swiftshader
mv OPEN_SOURCE_LICENSES.TXT ${prefix}/share/licenses/swiftshader
"""

# Dependencies that must be installed before this package can be built
dependencies = []

build_tarballs(ARGS, name, version, src_windows, script, [Windows(:x86_64)], [LibraryProduct("vk_swiftshader", :libvulkan)], dependencies)
build_tarballs(ARGS, name, version, src_linux, script, [Linux(:x86_64)], [LibraryProduct("libvulkan", :libvulkan)], dependencies)
build_tarballs(ARGS, name, version, src_macos, script, [MacOS(:x86_64)], [LibraryProduct("libvulkan", :libvulkan)], dependencies)
