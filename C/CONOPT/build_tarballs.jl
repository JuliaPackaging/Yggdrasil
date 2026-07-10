using BinaryBuilder
using Pkg

name = "CONOPT"
version = v"4.39.0"

sources = [
    ArchiveSource("https://d37drm4t2jghv5.cloudfront.net/conopt/4.39.0/conopt-4_39_0-linux-x86_64.zip", "8c67952f2023257bad039e8db1e0757bec93125c3e474ac028685b80643ee3e1"),
    ArchiveSource("https://d37drm4t2jghv5.cloudfront.net/conopt/4.39.0/conopt-4_39_0-linux-arm64.zip", "0afea1bfc9648ca84ded966f8fcaf6732d2ef9fe8c34c2c47e5a21abd13ecd07"),
    ArchiveSource("https://d37drm4t2jghv5.cloudfront.net/conopt/4.39.0/conopt-4_39_0-macos-x86_64.zip", "0fa8c13407441b04c0a6cad117fce726c5519c9ec4631630f58b7eee345add43"),
    ArchiveSource("https://d37drm4t2jghv5.cloudfront.net/conopt/4.39.0/conopt-4_39_0-macos-arm64.zip", "19a30264150eeb8016c91048468af20e6fc46a8c95c77951af8285c445379b29"),
    ArchiveSource("https://d37drm4t2jghv5.cloudfront.net/conopt/4.39.0/conopt-4_39_0-win-x86_64.zip", "2b14505d910b9e84a19795f9cb866c5295b24236b2bded6b133463a995d18bc4"),
    ArchiveSource("https://d37drm4t2jghv5.cloudfront.net/conopt/4.39.0/conopt-4_39_0-win-i386.zip", "399d9a40cde8e0b83e507e50d5dc1853c78831eeeed072217defdece10a26e14")
]

script = raw"""
cd ${WORKSPACE}/srcdir
mkdir -p ${libdir}

if [[ "${target}" == x86_64-linux-* ]]; then
    install -Dvm 755 conopt-linux-x86_64/lib/libconopt.so.4 ${libdir}/libconopt.so

elif [[ "${target}" == aarch64-linux-* ]]; then
    install -Dvm 755 conopt-linux-arm64/lib/libconopt.so.4 ${libdir}/libconopt.so

elif [[ "${target}" == x86_64-apple-* ]]; then
    install -Dvm 755 conopt-macos-x86_64/lib/libconopt.dylib ${libdir}/libconopt.dylib

elif [[ "${target}" == aarch64-apple-* ]]; then
    install -Dvm 755 conopt-macos-arm64/lib/libconopt.dylib ${libdir}/libconopt.dylib

elif [[ "${target}" == x86_64-w64-mingw32 ]]; then
    mkdir -p ${bindir}
    install -Dvm 755 conopt-win-x86_64/lib/conopt4.dll ${bindir}/conopt4.dll
elif [[ "${target}" == i686-w64-mingw32 ]]; then
    mkdir -p ${bindir}
    install -Dvm 755 conopt-win-i386/lib/conopt4.dll ${bindir}/conopt4.dll
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
