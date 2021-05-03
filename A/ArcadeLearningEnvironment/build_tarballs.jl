# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ArcadeLearningEnvironment"
version = v"0.6.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/mgbellemare/Arcade-Learning-Environment/archive/v0.6.1.tar.gz", "8059a4087680da03878c1648a8ceb0413a341032ecaa44bef4ef1f9f829b6dde"),
    FileSource("http://www.atarimania.com/roms/Roms.rar", "4e35879fbd3da7d008f80f8d3a48360b9513859aa6c694164e67d5a82daca498"),
    FileSource("https://raw.githubusercontent.com/mgbellemare/Arcade-Learning-Environment/v0.6.1/md5.txt", "218673cbeba56f3a7066293c259ae7b31ebece686bf3ff4ae4fe746e7d58a51e"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/
unrar e Roms.rar
unzip ROMS.zip
mkdir $prefix/roms
for f in ROMS/*; do md5=`md5sum "$f" | awk '{print $1}'`; newname=`grep $md5 md5.txt | awk '{print $2}'`; if [[ $newname != "" ]]; then cp "$f" $prefix/roms/$newname; fi; done
cd $WORKSPACE/srcdir/Arcade-Learning-Environment-*/
install_license $(pwd)/License.txt
atomic_patch -p1 ../patches/fix-dlext-macos.patch
atomic_patch -p1 ../patches/cmake-install-for-windows.patch
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DUSE_SDL=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_CPP_LIB=OFF \
    -DBUILD_CLI=OFF \
    -DCMAKE_CXX_FLAGS="-I${includedir}" \
    -DCMAKE_SHARED_LINKER_FLAGS_INIT="-L${libdir}" \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libale_c", :libale_c),
    FileProduct("roms", :roms_dir)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
