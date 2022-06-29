# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Exiv2"
version = v"0.27.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/Exiv2/exiv2/archive/refs/tags/v$(version).tar.gz", "9fb2752c92f63c9853e0bef9768f21138eeac046280f40ded5f37d06a34880d9"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/exiv2-*

if [[ "${target}" == x86_64-linux-musl ]]; then
    # Delete libexpat to prevent it from being picked up by mistake
    rm /usr/lib/libexpat.so*

elif [[ "${target}" == i686-linux-musl ]]; then

    #otherwise, patch fails with different line endings message
    dos2unix cmake/compilerFlags.cmake
    
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/i686-musl-comment-stack-protector-strong.patch

fi

mkdir build
cd build/

cmake .. \
-DCMAKE_INSTALL_PREFIX=$prefix \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release \
-DEXIV2_BUILD_SAMPLES=OFF \
-DIconv_INCLUDE_DIR=${includedir}

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))


# The products that we will ensure are always built
products = [
    LibraryProduct("libexiv2", :libexiv2),
    ExecutableProduct("exiv2", :exiv2)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency("Expat_jll"; compat="2.2.10")
    Dependency(PackageSpec(name="libpng_jll", uuid="b53b4c65-9356-5827-b1ea-8c7a1a84506f"))
    Dependency(PackageSpec(name="Libiconv_jll", uuid="94ce4f54-9a6c-5748-9c1c-f9c7231a4531"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
