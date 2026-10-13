# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mctc_lib"
version = v"0.6.1"

sources = [
    GitSource("https://github.com/grimme-lab/mctc-lib.git",
              "c86c80002e74e7cfc48b7cc9878dd9caa85d4e70"),
]

# JSON input needs jonquil, which is not packaged yet
script = raw"""
# The rootfs ships meson 1.8.0, which upstream rejects because of a known bug.
# Install a newer meson into a private directory.
python3 -m pip install --ignore-installed --target=/tmp/meson meson==1.11.2
export PYTHONPATH="/tmp/meson${PYTHONPATH:+:${PYTHONPATH}}"
export PATH="/tmp/meson/bin:${PATH}"

cd ${WORKSPACE}/srcdir/mctc-lib
meson setup build \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    --prefix=${prefix} \
    --buildtype=release \
    --wrap-mode=nodownload \
    -Ddefault_library=shared \
    -Djson=disabled
meson compile -C build -j${nproc}
meson install -C build
install_license LICENSE
"""

platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)
# Downstream packages use the installed .mod files, keep the whole stack on the same GCC
filter!(p -> libgfortran_version(p) >= v"5", platforms)

products = [
    # Windows DLL names may have the -0 suffix, so list both version
    LibraryProduct(["libmctc-lib", "libmctc-lib-0"], :libmctc_lib),
    ExecutableProduct("mctc-convert", :mctc_convert),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")
