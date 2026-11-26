# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
# inside julia, run once: using Pkg; Pkg.add("BinaryBuilder")
# example of command to build a giac package for one architecture
# julia build_tarballs.jl --verbose --debug x86_64-w64-mingw32

using BinaryBuilder, Pkg

name = "GIAC"
version = v"2.1.0"

# The JLL version is decoupled from the upstream version, as for PARI_jll and
# FLINT_jll. The ABI of this JLL can change without an upstream major release:
# GIAC_jll 2.0.2 and 2.0.3 were built from the JuliaGiac fork with an 8-bit
# type field in `gen`, and this release goes back to upstream's 5-bit layout;
# libgiac itself is always libgiac.so.0, so its soname does not tell ABIs
# apart. Upstream X.Y.Z maps to X00.Y00.Z00, e.g. 2.1.0 -> 200.100.0: no
# compat bound written for the 2.0.x JLLs (`"=2.0.3"` in libgiac_julia,
# `"2.0.1 - 2"` in Giac.jl) admits it.
#
# Packages depending on this JLL should use `~` in their compat ranges, e.g.
# `compat="~200.100.0"`. The JLL patch level can then be bumped for rebuilds,
# and a rebuild that breaks ABI without an upstream change can bump the minor
# version (200.100.0 -> 200.101.0).
ygg_version = VersionNumber(100 * version.major, 100 * version.minor,
                            100 * version.patch)

# Collection of sources required to build GIAC
# Using the Meson-based fork from https://github.com/JuliaGiac/giac
sources = [
    GitSource("https://github.com/JuliaGiac/giac.git",
        "312e89285a1edd56383c057a27378a40e6c2446c"),  # dev: upstream giac 2.1.0, PARI 2.19, upstream's 5-bit type field
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

# Configure with Meson. GSL/LAPACK/GLPK/PARI are enabled; the remaining
# optional dependencies are disabled.
meson setup build \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    --buildtype=release \
    -Dgui=disabled \
    -Dpari=enabled \
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
    Dependency("PARI_jll"; compat="~200.1900.100"),
    # Readline_jll pulls Ncurses_jll, whose 6.6.1 and later builds (BinaryBuilder2)
    # reference musl 1.2 time64 symbols (`__clock_gettime64` etc.) on 32-bit musl,
    # which our musl sysroot lacks, so linking icas fails. Build against the
    # previous Ncurses instead, as H/HDF5 does for XML2. This works at run time on
    # musl >= 1.2, and fails with an error message otherwise.
    BuildDependency(PackageSpec(; name="Ncurses_jll", version=v"6.6.0+2");
                    platforms=filter(p -> Sys.islinux(p) && libc(p) == "musl" && nbits(p) == 32, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
# preferred_gcc_version aligned with libgiac_julia_jll's recipe (Giac.jl#22).
# Since 2.1.0 `gen` uses upstream's 5-bit type bitfield again (the 8-bit
# type gave wrong integrals from the second call on): libgiac and every
# consumer must keep being built with the same GCC.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
  clang_use_lld=false, preferred_gcc_version=v"10", julia_compat="1.10")
