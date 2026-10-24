# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "multicharge"
version = v"0.5.0"

sources = [
    GitSource("https://github.com/grimme-lab/multicharge.git",
              "6a5d63f9e9e29dcf13cc47cc27f33bf9015681bf";
              tag="v$(version)"),
    DirectorySource("./bundled"),
]

script = raw"""
# The rootfs ships meson 1.8.0, which upstream rejects because of a known bug.
# Install a newer meson into a private directory.
python3 -m pip install --ignore-installed --target=/tmp/meson meson==1.11.2
export PYTHONPATH="/tmp/meson${PYTHONPATH:+:${PYTHONPATH}}"
export PATH="/tmp/meson/bin:${PATH}"

cd ${WORKSPACE}/srcdir/multicharge
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/optional-mstore.patch

# On FreeBSD, meson-built dependencies ship their pkg-config files in libdata/pkgconfig,
# which is not on the default search path.
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:+${PKG_CONFIG_PATH}:}${prefix}/libdata/pkgconfig"

if [[ "${target}" == *mingw* ]]; then
    LBT="blastrampoline-5"
else
    LBT="blastrampoline"
fi

# GCC is used for C as well so that meson's OpenMP check succeeds for both languages
meson setup build \
    --cross-file="${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson" \
    --prefix=${prefix} \
    --buildtype=release \
    --wrap-mode=nodownload \
    -Ddefault_library=shared \
    -Dlapack=custom \
    -Dcustom_libraries="-L${libdir},${LBT}"
meson compile -C build -j${nproc}
meson install -C build
install_license LICENSE
"""

platforms = expand_gfortran_versions(supported_platforms())

products = [
    LibraryProduct(["libmulticharge", "libmulticharge-0"], :libmulticharge),
    ExecutableProduct("multicharge", :multicharge),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"); compat="5.4.0"),
    Dependency("mctc_lib_jll"; compat="0.6.1"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"9")
