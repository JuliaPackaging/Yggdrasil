# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Torch"
version = v"1.10.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/dhairyagandhi96/Torch.jl.git", "85bd08d39e7fba29ec4a643f60dd006ed8be8ede"),
    ArchiveSource("https://download.pytorch.org/libtorch/cpu/libtorch-shared-with-deps-1.10.2%2Bcpu.zip", "fa3fad287c677526277f64d12836266527d403f21f41cc2e7fb9d904969d4c4a"; unpack_target = "x86_64-linux-gnu-cxx03"),
    ArchiveSource("https://download.pytorch.org/libtorch/cpu/libtorch-cxx11-abi-shared-with-deps-1.10.2%2Bcpu.zip", "83e43d63d0e7dc9d57ccbdac8a8d7edac6c9e18129bf3043be475486b769a9c2"; unpack_target = "x86_64-linux-gnu-cxx11"),
    ArchiveSource("https://download.pytorch.org/libtorch/cpu/libtorch-macos-1.10.2.zip", "d1711e844dc69c2338adfc8ce634806a9ae36e54328afbe501bafd2d70f550e2"; unpack_target = "x86_64-apple-darwin14"),
    ArchiveSource("https://download.pytorch.org/libtorch/cpu/libtorch-win-shared-with-deps-1.10.2%2Bcpu.zip", "0ce2ccd959704cd85c44ad1f3f335c56734c7ff09418bd563e07d5bb7142510c"; unpack_target = "x86_64-w64-mingw32"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

if [[ $target == *linux* ]]; then
    echo "target: $target"; echo "bb_target: $bb_target"; echo "bb_full_target: $bb_full_target"
    cd $bb_full_target
else
    cd $target
fi
mv libtorch/share/* $prefix/share/
mv libtorch/lib/* $prefix/lib/
rm -r libtorch/lib
rm -r libtorch/share
mv libtorch/* $prefix
rm -r libtorch

cd $WORKSPACE/srcdir/Torch.jl/build
mkdir build && cd build
cmake -DCMAKE_PREFIX_PATH=$prefix -DTorch_DIR=$prefix/share/cmake/Torch ..
cmake --build .

mkdir -p "${libdir}"
cp -r $WORKSPACE/srcdir/Torch.jl/build/build/*.${dlext} "${libdir}"
install_license ${WORKSPACE}/srcdir/Torch.jl/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),
]
platforms = expand_cxxstring_abis(platforms; skip = !Sys.islinux)

# The products that we will ensure are always built
products = [
    LibraryProduct("libdoeye_caml", :libdoeye_caml, dont_dlopen = true),
    LibraryProduct("libtorch", :libtorch, dont_dlopen = true),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7.1.0")
