# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "KaHyPar"
version = v"1.2.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/kahypar/kahypar.git", "971c38a4c7b7ed1ecf001d0263c1099cbc72886e"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd kahypar/
git submodule update --init --recursive --depth=1
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make install.library
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("x86_64", "macos"; ),
    Platform("x86_64", "freebsd"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libkahypar", :libkahypar)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Boost breaks ABI in every single version because they embed the full version number in
    # the SONAME, so we're compatible with one and only one version at a time.
    Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75"); compat="=1.71.0")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7")
