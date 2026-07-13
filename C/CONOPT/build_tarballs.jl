using BinaryBuilder
using Pkg

name = "CONOPT"
version = v"4.39.1"

# We map each download to extract into its standard BinaryBuilder triplet folder
sources = [
    ArchiveSource("https://d37drm4t2jghv5.cloudfront.net/conopt/4.39.1/conopt-4_39_1-linux-x86_64.zip", "f1a42b849eb8f5760514261aea9e71e77d91762ea98b1819d9554d6d5ee430c0"; unpack_target="x86_64-linux-gnu"),
    ArchiveSource("https://d37drm4t2jghv5.cloudfront.net/conopt/4.39.1/conopt-4_39_1-linux-arm64.zip", "85336dbc8bce236b21fb7d0aa606c4634cc3644aba686cbcff6b81f67aabc102"; unpack_target="aarch64-linux-gnu"),
    ArchiveSource("https://d37drm4t2jghv5.cloudfront.net/conopt/4.39.1/conopt-4_39_1-macos-x86_64.zip", "86c3f8e50ad232e77feafbb343a8708d5ac883a10a9adc84f18bc3ce251e6cd1"; unpack_target="x86_64-apple-darwin14"),
    ArchiveSource("https://d37drm4t2jghv5.cloudfront.net/conopt/4.39.1/conopt-4_39_1-macos-arm64.zip", "5d6f098c5f95d19cd2a8b3fae91c41135bdef636373486edddd7aa9a1cafcd02"; unpack_target="aarch64-apple-darwin20"),
    ArchiveSource("https://d37drm4t2jghv5.cloudfront.net/conopt/4.39.1/conopt-4_39_1-win-x86_64.zip", "4435bb5eaa181fd01640fb24c382414263907cbcf1c413201163dfa8d3db888c"; unpack_target="x86_64-w64-mingw32"),
    ArchiveSource("https://d37drm4t2jghv5.cloudfront.net/conopt/4.39.1/conopt-4_39_1-win-i386.zip", "cfeb54f3725a360d560663d860d11fa85a5e81233b0a3530e40b59676ba942c3"; unpack_target="i686-w64-mingw32")
]

# Because of unpack_target, we can just cd directly into ${target} and let 
# bash wildcards handle the inner conopt-* folder name. 
script = raw"""
cd ${WORKSPACE}/srcdir/${target}/conopt-*
mkdir -p ${libdir} ${bindir}

if [[ "${target}" == *-linux-* ]]; then
    install -Dvm 755 lib/libconopt.so.4 ${libdir}/libconopt.so

elif [[ "${target}" == *-apple-* ]]; then
    install -Dvm 755 lib/libconopt.dylib ${libdir}/libconopt.dylib

elif [[ "${target}" == *-mingw32 ]]; then
    install -Dvm 755 lib/conopt4.dll ${bindir}/conopt4.dll
fi
"""

platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
    Platform("i386", "windows")
]

platforms = expand_gfortran_versions(platforms)

products = [
    LibraryProduct(["libconopt", "conopt4"], :libconopt)
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
