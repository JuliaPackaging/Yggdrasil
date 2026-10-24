# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "dftd4"
version = v"4.3.0"

sources = [
    GitSource("https://github.com/dftd4/dftd4.git",
              "d5f891808c2145becdcce742f67ecc7e711067d7";
              tag="v$(version)"),
    DirectorySource("./bundled"),
]

script = raw"""
# The rootfs ships meson 1.8.0, which upstream rejects because of a known bug.
# Install a newer meson into a private directory
python3 -m pip install --ignore-installed --target=/tmp/meson meson==1.11.2
export PYTHONPATH="/tmp/meson${PYTHONPATH:+:${PYTHONPATH}}"
export PATH="/tmp/meson/bin:${PATH}"

cd ${WORKSPACE}/srcdir/dftd4
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
install_license COPYING COPYING.LESSER
"""

platforms = expand_gfortran_versions(supported_platforms())

# dftd4 requires the ieee_arithmetic module, which gfortran does not provide on these targets
platforms = filter!(platforms) do p
    libc(p) == "musl" && arch(p) in ("aarch64", "armv6l", "armv7l") && return false
    Sys.isfreebsd(p) && arch(p) == "aarch64" && return false
    true
end

products = [
    LibraryProduct(["libdftd4", "libdftd4-4"], :libdftd4),
    ExecutableProduct("dftd4", :dftd4),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"); compat="5.4.0"),
    Dependency("mctc_lib_jll"; compat="0.6.1"),
    Dependency("multicharge_jll"; compat="0.5.0"),
]

# libblastrampoline_jll 5.4 requires Julia 1.10
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"9")
