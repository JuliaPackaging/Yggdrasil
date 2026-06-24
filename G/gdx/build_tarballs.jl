# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gdx"
version = v"7.11.20"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/GAMS-dev/gdx.git", "c6417bbbd0cd3c620f7b705b15ec8474fbbacd5b"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gdx/

if [[ "${target}" == *mingw* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/winfloat.patch;
fi

cmake -S . -B build \
    --install-prefix ${prefix} \
    --toolchain ${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS=${C_FLAGS} \
    -DCMAKE_CXX_FLAGS=${C_FLAGS} \
    -DNO_TESTS=ON \
    -DNO_EXAMPLES=ON \
    -DNO_TOOLS=ON
cmake --build build --parallel ${nproc}
cmake --install build

install -Dvm 755 build/libgdxcclib64.${dlext} -t ${libdir}
install -Dvm 644 generated/*.h -t ${includedir}
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("x86_64", "macos"; ),
    Platform("aarch64", "macos"; ),
    Platform("x86_64", "windows"; ),
]

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libgdxcclib64", :libgdx)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"11.1.0")

