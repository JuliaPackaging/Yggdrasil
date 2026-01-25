using BinaryBuilder, Pkg

name = "tblite"
version = v"0.5.0"

sources = [
    # Main source
    ArchiveSource("https://github.com/tblite/tblite/releases/download/v$(version)/tblite-$(version).tar.xz",
                  "e8a70b72ed0a0db0621c7958c63667a9cd008c97c868a4a417ff1bc262052ea8"),

    # Dependencies (Subprojects)
    ArchiveSource("https://github.com/toml-f/toml-f/releases/download/v0.4.3/toml-f-0.4.3.tar.xz",
                  "0b53cf9ec98eff01a81d956e9ef851c16b3c6b49c934d0665b43db9f6ee39953"),

    ArchiveSource("https://github.com/grimme-lab/mctc-lib/releases/download/v0.5.1/mctc-lib-0.5.1.tar.xz",
                  "a93ea3e50a1950745df01601bfd672d485f0367660f7076dbe73e422e7d4e2ac"),

    GitSource("https://github.com/dftd3/simple-dftd3.git", "3425201769e7c56e98e3831f9bdb7be71cfaec0d"), # 1.2.1

    ArchiveSource("https://github.com/dftd4/dftd4/releases/download/v4.0.1/dftd4-4.0.1-source.tar.xz",
                  "d3781763390c349794d70663e4e54e368d19a5869c98fe939b32e9069432201b"),
]

script = raw"""
cd $WORKSPACE/srcdir/tblite-*/

# Prepare subprojects directory
mkdir -p subprojects

# Move and rename dependency folders to match what Meson expects (project name)
# The glob patterns handle the version suffix stripping
mv ../toml-f-*/       subprojects/toml-f
mv ../mctc-lib-*/     subprojects/mctc-lib
mv ../simple-dftd3/ subprojects/simple-dftd3
mv ../dftd4-*/        subprojects/dftd4

# Build directory
mkdir build

# Configure
# -Ddefault_library=shared ensures the main libtblite is shared
# Meson usually statically links subprojects into the main library unless told otherwise
meson setup build \
    --cross-file=${MESON_TARGET_TOOLCHAIN} \
    --prefix=${prefix} \
    --buildtype=release \
    -Ddefault_library=shared \
    -Dlapack=openblas \
    -Dsimple-dftd3:apiversion=1.2.1 \
    -Ddftd4:lapack=openblas

# Compile and Install
meson compile -C build -j${nproc}
meson install -C build
"""

platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

products = [
    LibraryProduct("libtblite", :libtblite),
    ExecutableProduct("tblite", :tblite),
]

dependencies = [
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               julia_compat="1.6", preferred_gcc_version=v"9")
