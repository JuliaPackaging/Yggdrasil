# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Antic"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/wbhart/antic.git", "4efeec6d538217d647f91e1754654e0643269977"),
    FileSource("https://raw.githubusercontent.com/wbhart/antic/f506971449186eac57bb9d44682013c1e7f5cdc6/LICENSE", "dc626520dcd53a22f727af3ee42c770e56c97a64fe3adb063799d8ab032fe551"),
    FileSource("https://raw.githubusercontent.com/wbhart/antic/f506971449186eac57bb9d44682013c1e7f5cdc6/gpl-2.0.txt", "8177f97513213526df2cf6184d8ff986c675afb514d4e68a404010521b880643"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd antic/

if [[ ${target} == *musl* ]]; then
   export CFLAGS=-D_GNU_SOURCE=1;
elif [[ ${target} == *mingw* ]]; then
   sed -i -e "s#/lib\>#/$(basename ${libdir})#g" configure
   extraflags=--build=MINGW${nbits};
fi

./configure --prefix=$prefix --disable-static --enable-shared --with-gmp=$prefix --with-mpfr=$prefix --with-flint=$prefix ${extraflags}
make -j${nproc}
make install LIBDIR=$(basename ${libdir})
install_license gpl-2.0.txt
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libantic", :libarb)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="FLINT_jll", uuid="e134572f-a0d5-539d-bddf-3cad8db41a82"))
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"))
    Dependency(PackageSpec(name="MPFR_jll", uuid="3a97d323-0669-5f0c-9066-3539efd106a3"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
