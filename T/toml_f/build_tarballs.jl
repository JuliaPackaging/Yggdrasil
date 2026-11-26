# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "toml_f"
version = v"0.5.2"

sources = [
    GitSource("https://github.com/toml-f/toml-f.git",
              "28f4601fe0992ed17a6b97e230a61289f56bcd8e"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/toml-f
meson setup build \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    --prefix=${prefix} \
    --buildtype=release \
    -Ddefault_library=shared \
    -Dtests=false
meson compile -C build -j${nproc}
meson install -C build
install_license LICENSE-Apache LICENSE-MIT
"""

platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)
# Downstream packages use the installed .mod files, keep the whole stack on the same GCC
filter!(p -> libgfortran_version(p) >= v"5", platforms)

products = [
    # Windows DLL names may have the -0 suffix, so list both versions
    LibraryProduct(["libtoml-f", "libtoml-f-0"], :libtoml_f),
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")
