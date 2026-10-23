# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "simple_dftd3"
version = v"1.6.0"

sources = [
    GitSource("https://github.com/dftd3/simple-dftd3.git",
              "6004cfd62ad2a248ad32167392bd08c674da6161"),
    DirectorySource("./bundled"),
]

script = raw"""
# The rootfs ships meson 1.8.0, which upstream rejects because of a known bug.
# Install a newer meson into a private directory
python3 -m pip install --ignore-installed --target=/tmp/meson meson==1.11.2
export PYTHONPATH="/tmp/meson${PYTHONPATH:+:${PYTHONPATH}}"
export PATH="/tmp/meson/bin:${PATH}"

cd ${WORKSPACE}/srcdir/simple-dftd3
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/optional-mstore.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/no-ieee-arithmetic.patch

# On FreeBSD, meson-built dependencies ship their pkg-config files in libdata/pkgconfig,
# which is not on the default search path.
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:+${PKG_CONFIG_PATH}:}${prefix}/libdata/pkgconfig"

# GCC is used for C as well so that meson's OpenMP check succeeds for both languages
meson setup build \
    --cross-file="${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson" \
    --prefix=${prefix} \
    --buildtype=release \
    --wrap-mode=nodownload \
    -Ddefault_library=shared
meson compile -C build -j${nproc}
meson install -C build
install_license COPYING COPYING.LESSER
"""

platforms = expand_gfortran_versions(supported_platforms())

products = [
    LibraryProduct(["libs-dftd3", "libs-dftd3-1"], :libsdftd3),
    ExecutableProduct("s-dftd3", :s_dftd3),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("mctc_lib_jll"; compat="0.6.1"),
    Dependency("toml_f_jll"; compat="0.5.2"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")
