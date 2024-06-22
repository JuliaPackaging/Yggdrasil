# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "WIGXJPF"
version = v"1.13.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://fy.chalmers.se/subatom/wigxjpf/wigxjpf-latest.tar.gz", "90ab9bfd495978ad1fdcbb436e274d6f4586184ae290b99920e5c978d64b3e6a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wigxjpf-1.13


# Patch the CMake workflow to fix the install directories and build the libraries as shared libraries
echo -e "include(GNUInstallDirs)\n$(cat CMakeLists.txt)" > CMakeLists.txt
sed -i 's/STATIC//' CMakeLists.txt

mkdir -p build && cd build

cmake -B . -S .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON

cmake --build . --parallel ${nproc}
cmake --install .

cp README $WORKSPACE/destdir/shared/licenses/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libwigxjpf_shared", :wigxjpf)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
