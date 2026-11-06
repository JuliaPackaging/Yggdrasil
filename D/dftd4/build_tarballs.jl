# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "dftd4"
version = v"4.3.0"

# Use the meson source distribution (note: we need the *.tar.xz, not the *.tar.gz,
# which is the python sdist)
sources = [
    ArchiveSource("https://github.com/dftd4/dftd4/releases/download/v$(version)/dftd4-$(version).tar.xz",
                  "e94c5d021c0a4b4aa9b5587e36fda2f398271dc2dc1abfbe097fdb04022bef35"),
]

script = raw"""
# The rootfs ships meson 1.8.0, which upstream rejects because of a known bug.
# Install a newer meson into a private directory
python3 -m pip install --ignore-installed --target=/tmp/meson meson==1.11.2
export PYTHONPATH="/tmp/meson${PYTHONPATH:+:${PYTHONPATH}}"
export PATH="/tmp/meson/bin:${PATH}"

cd ${WORKSPACE}/srcdir/dftd4-*

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
platforms = filter!(p -> !(libc(p) == "musl" && arch(p) == "aarch64"), platforms)
platforms = filter!(p -> !(libc(p) == "musl" && arch(p) == "armv6l"),  platforms)
platforms = filter!(p -> !(libc(p) == "musl" && arch(p) == "armv7l"),  platforms)
platforms = filter!(p -> !(Sys.isfreebsd(p)  && arch(p) == "aarch64"), platforms)

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
