# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "perfetto"
version = v"51.2.0"

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/google/perfetto",
        "7a9a6a0587348bffd1796b66a1da33cc1ea421d8"
    ),
    DirectorySource("./bundled"),
]


# Bash recipe for building across all platforms
script = raw"""
apk del cmake
cd $WORKSPACE/srcdir/perfetto
atomic_patch -p1 ../shared_lib.patch
atomic_patch -p1 ../perfetto_mingw.patch

mkdir build && cd build
meson setup .. --cross-file="${MESON_TARGET_TOOLCHAIN}" --buildtype=release
ninja -j${nproc}
ninja install
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libperfetto", :libperfetto),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec(; name = "CMake_jll", version = v"3.24.3")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat = "1.6", preferred_gcc_version = v"9", clang_use_lld = false,
)
