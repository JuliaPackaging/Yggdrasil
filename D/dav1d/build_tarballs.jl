# Note that this script can accept some limited command-line arguments,
# run `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "dav1d"
version = v"1.5.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://code.videolan.org/videolan/dav1d/-/archive/$(version)/dav1d-$(version).tar.bz2",
                  "4eddffd108f098e307b93c9da57b6125224dc5877b1b3d157b31be6ae8f1f093"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/dav1d-*

# Avoid problems with `-Werror=unused-command-line-argument`
sed -i -e 's!/opt/bin/.*-clang!'${WORKSPACE}/srcdir/files/cc'!' ${MESON_TARGET_TOOLCHAIN}
sed -i -e 's!/opt/bin/.*-clang[+][+]!'${WORKSPACE}/srcdir/files/c++'!' ${MESON_TARGET_TOOLCHAIN}

flags=
if [[ ${target} == powerpc64le-* ]]; then
    # These macros are defined in glibc, but our glibc is too old
    flags='-DAT_HWCAP2=26 -DPPC_FEATURE2_ARCH_3_00=0x00800000'
fi

mkdir build && cd build
meson setup --cross-file="${MESON_TARGET_TOOLCHAIN}" --buildtype=release -Denable_tests=false -Dc_args="${flags}" -Dcpp_args="${flags}" ..
ninja -j${nproc}
ninja install
install_license ../COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("dav1d", :dav1d),
    LibraryProduct("libdav1d", :libdav1d),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("NASM_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Need at least GCC 6 for Atomics and to avoid ICEs
# Need at least GCC 8 for PowerPC intrinsics
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"8")
