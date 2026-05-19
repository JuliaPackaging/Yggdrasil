# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
# inside julia, run once: using Pkg; Pkg.add("BinaryBuilder")
# example of command to build a giac package for one architecture
# julia build_tarballs.jl --verbose --debug x86_64-w64-mingw32

using BinaryBuilder, Pkg

name = "GIAC"
version = v"2.0.2"

# Collection of sources required to build GIAC
# Using the Meson-based fork from https://github.com/s-celles/giac
sources = [
    GitSource("https://github.com/s-celles/giac.git",
        "64fdcefb45d0599e60083e785a3cc033e74714ee"),  # dev branch + GIAC_TYPE_ON_8BITS default
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/giac*

# Determine gettext option: FreeBSD doesn't have libintl via Gettext_jll
GETTEXT_OPT="auto"
if [[ "${target}" == *freebsd* ]]; then
    GETTEXT_OPT="disabled"
fi

# Meson's dependency('blas')/dependency('lapack') want blas.pc/lapack.pc, but
# OpenBLAS_jll only ships openblas.pc. Provide self-contained wrapper .pc
# files (skip on macOS — Giac will detect the Accelerate framework instead).
if [[ "${target}" != *apple-darwin* ]]; then
    mkdir -p ${prefix}/lib/pkgconfig
    cat > ${prefix}/lib/pkgconfig/blas.pc <<EOF
prefix=${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: blas
Description: BLAS interface provided by OpenBLAS
Version: 0.3
Libs: -L\${libdir} -lopenblas
Cflags: -I\${includedir}
EOF
    cat > ${prefix}/lib/pkgconfig/lapack.pc <<EOF
prefix=${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: lapack
Description: LAPACK interface provided by OpenBLAS
Version: 0.3
Libs: -L\${libdir} -lopenblas
Cflags: -I\${includedir}
EOF
fi

# GLPK_jll ships no pkg-config file, so provide one.
mkdir -p ${prefix}/lib/pkgconfig
cat > ${prefix}/lib/pkgconfig/glpk.pc <<EOF
prefix=${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: glpk
Description: GNU Linear Programming Kit
Version: 5.0
Libs: -L\${libdir} -lglpk
Cflags: -I\${includedir}
EOF

# Configure with Meson, disabling all optional dependencies
meson setup build \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    --buildtype=release \
    -Dgui=disabled \
    -Dpari=disabled \
    -Dntl=disabled \
    -Dcocoa=disabled \
    -Dgsl=enabled \
    -Dlapack=enabled \
    -Decm=disabled \
    -Dglpk=enabled \
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
    Dependency("GSL_jll"; compat="2.8.1"),
    # OpenBLAS32_jll = LP64 (32-bit integers, standard C ABI) — OpenBLAS_jll
    # itself is ILP64 with _64_ symbol suffixes which Giac doesn't expect.
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("GLPK_jll"; compat="5.0.2"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# preferred_gcc_version aligned with libgiac_julia_jll's recipe (Giac.jl#22).
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
  clang_use_lld=false, preferred_gcc_version=v"10", julia_compat="1.10")
