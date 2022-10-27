# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mimalloc"
version = v"2.0.6"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/microsoft/mimalloc.git",
              "82712f4a8f038a7fb4df2790f4c3b7e3ed9e219b"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mimalloc/
if [[ "${target}" == i686-*-mingw* ]]; then
    atomic_patch -p1 ../patches/mimalloc-redirect32.patch
fi
mkdir -p build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DMI_BUILD_OBJECT=OFF \
    -DMI_INSTALL_TOPLEVEL=ON \
    -DMI_BUILD_TESTS=OFF \
    -DMI_OVERRIDE=OFF \
    ..
make -j ${nproc}
make -j ${nproc} install
# Manually install the mimalloc-redirect lib for Windows
if [[ "${target}" == i686-*-mingw* ]]; then
    cp "mimalloc-redirect32.${dlext}" "${libdir}/."
elif [[ "${target}" == x86_64-*-mingw* ]]; then
    cp "mimalloc-redirect.${dlext}" "${libdir}/."
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmimalloc", :libmimalloc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"6.1.0")
