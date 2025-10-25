# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "quickfixc"
version = v"0.1.1"

# Collection of sources required to build CMake
sources = [
    GitSource("https://github.com/AlexKlo/quickfixc.git", "77eb7cd5ba60b2b0acedfea377f516c1d2c7a60c"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/quickfixc

for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

mkdir build && cd build

cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..

make -j${nproc} install
"""

platforms = supported_platforms(;
    exclude = p -> 
    arch(p) == "riscv64" ||
    (Sys.islinux(p) && arch(p) == "i686" && libc(p) == "musl") || 
    (Sys.isfreebsd(p) && arch(p) == "aarch64") || 
    Sys.iswindows(p),
)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libquickfixc", :libquickfixc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll"; compat="3.0.16"),
    Dependency("quickfix_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.8", preferred_gcc_version=v"9")
