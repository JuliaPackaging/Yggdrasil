using BinaryBuilder

name = "MKL"
version = v"2020.0.166"

sources = [
    FileSource("https://anaconda.org/anaconda/mkl/2020.0/download/linux-64/mkl-2020.0-166.tar.bz2",
               "59154b30dd74561e90d547f9a3af26c75b6f4546210888f09c9d4db8f4bf9d4c"; unpack_target = "mkl-x86_64-linux-gnu"),
    FileSource("https://anaconda.org/anaconda/mkl/2020.0/download/osx-64/mkl-2020.0-166.tar.bz2",
               "b45713c9f72d225e28d489bd6e9f4dc02622e6b4e4253050ebc026db4d292247"; unpack_target = "mkl-x86_64-apple-darwin14"),
    FileSource("https://anaconda.org/anaconda/mkl/2020.0/download/win-32/mkl-2020.0-166.tar.bz2",
               "78fbe6dfec291ba3332862bface5814cb0f128564bd4b99da53434ec6dd162a7"; unpack_target = "mkl-i686-w64-mingw32"),
    FileSource("https://anaconda.org/anaconda/mkl/2020.0/download/win-64/mkl-2020.0-166.tar.bz2",
               "c44096070fc5a5df0548c1168bcc464303d2757502ab2332f2184842d8eb7404"; unpack_target = "mkl-x86_64-w64-mingw32"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/mkl-${target}
if [[ ${target} == *mingw* ]]; then
    cp -r Library/bin/* ${libdir}
    install_license info/*.txt
else
    cp -r lib/* ${libdir}
    install_license info/licenses/*.txt
fi
"""

platforms = [
    Linux(:x86_64, libc=:glibc),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64),
]

# The products that we will ensure are always built
products = [
    LibraryProduct(["libmkl_core", "mkl_core"], :libmkl_core),
    LibraryProduct(["libmkl_rt", "mkl_rt"], :libmkl_rt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("IntelOpenMP_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; lazy_artifacts = true)
