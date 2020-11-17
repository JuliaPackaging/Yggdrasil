# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TDLib"
version = v"1.6.10"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/tdlib/td.git", "78e45da6b9014f8efd96cee0ad5701464d911cc7")
]

# Bash recipe for building across all platforms
script = raw"""
apk add gperf
cd td/
install_license LICENSE_1_0.txt
sed -i 's|TD_HAS_MMSG 1|TD_HAS_MMSG 0|' tdutils/td/utils/port/config.h  # otherwise not compatible with old glibc
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DZLIB_LIBRARY=$libdir -DZLIB_INCLUDE_DIR=$includedir ..
for f in $(grep -l $(find . -name link.txt) -e 'opt/bin/c++')
do
    # without this flag it cannot find libz
    sed -i ' 1 s/$/ -lz/' $f
done
cmake --build . -j${nproc}
cp libtdjson.${dlext} $libdir/libtdjson.${dlext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p -> Sys.islinux(p) && (libc(p) == "glibc" && arch(p) == "i686" || arch(p) == "x86_64"), supported_platforms())
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libtdjson", :libtdjson)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency.(["OpenSSL_jll", "Zlib_jll"])

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7")
