# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
# inside julia, run once: using Pkg; Pkg.add("BinaryBuilder")
# example of command to build a giac package for one architecture
# julia build_tarballs.jl --verbose --debug x86_64-w64-mingw32

using BinaryBuilder, Pkg

name = "GIAC"
version = v"2.0.1"

# Collection of sources required to build GIAC
# Using the Meson-based fork from https://github.com/s-celles/giac
sources = [
    GitSource("https://github.com/s-celles/giac.git",
        "194ff510872c5b871e316bf5c7dfbe942273bef8"),  # dev branch
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/giac*

# Determine gettext option: FreeBSD doesn't have libintl via Gettext_jll
GETTEXT_OPT="auto"
if [[ "${target}" == *freebsd* ]]; then
    GETTEXT_OPT="disabled"
fi

# Configure with Meson, disabling all optional dependencies
meson setup build \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    -Dgui=disabled \
    -Dpari=disabled \
    -Dntl=disabled \
    -Dcocoa=disabled \
    -Dgsl=disabled \
    -Dlapack=disabled \
    -Decm=disabled \
    -Dglpk=disabled \
    -Dpng=disabled \
    -Dao=disabled \
    -Dsamplerate=disabled \
    -Dcurl=disabled \
    -Dreadline=auto \
    -Dmicropython=disabled \
    -Dquickjs=disabled \
    -Dlibbf=disabled \
    -Djni=disabled \
    -Dgettext=${GETTEXT_OPT}

meson compile -C build -j${nproc}
meson install -C build

# Install aide_cas help data to share/giac/ so giac's built-in
# bin/../share/giac/ fallback finds it automatically
mkdir -p ${prefix}/share/giac
cp doc/aide_cas ${prefix}/share/giac/aide_cas

install_license COPYING
"""

# Build for all supported platforms
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libgiac", :libgiac),
    ExecutableProduct("icas", :icas),
    FileProduct("share/giac/aide_cas", :aide_cas),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Gettext_jll"; compat="0.21.0"),
    Dependency("GMP_jll"; compat="6.2.1"),
    Dependency("MPFR_jll"; compat="4.1.1"),
    Dependency("Readline_jll"; compat="8.2.13"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
  clang_use_lld=false, preferred_gcc_version=v"8", julia_compat="1.10")
