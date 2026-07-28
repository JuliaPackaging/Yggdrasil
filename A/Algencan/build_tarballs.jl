# Yggdrasil recipe for Algencan (TANGO project) — an augmented-Lagrangian
# nonlinear programming solver by E. G. Birgin and J. M. Martínez.
#
# This builds the stand-alone Fortran library WITHOUT HSL. The HSL linear
# solvers (MA57/MA86/MA97) are proprietary and cannot be redistributed, so this
# JLL matches the default "easy way" build of NLPModelsAlgencan.jl (dummy HSL).
# It removes the local build-time dependencies (gfortran + a working linker),
# but does NOT change Algencan's numerics — for HSL-backed performance, users
# still need a source build with their own HSL.
#
# To deploy: copy the `A/Algencan/` directory into a clone of
# https://github.com/JuliaPackaging/Yggdrasil and open a PR.
#
# Build & test locally for a single platform (needs Docker/BinaryBuilder):
#   julia --project build_tarballs.jl --verbose --debug aarch64-apple-darwin
#   julia --project build_tarballs.jl --verbose --debug x86_64-linux-gnu

using BinaryBuilder, Pkg

name = "Algencan"
version = v"3.1.1"

# Mirror of the upstream tarball from
# https://www.ime.usp.br/~egbirgin/tango/sources/algencan-3.1.1.tgz, republished
# on a GitHub release for long-term reproducibility (the upstream location is a
# personal academic URL). The file is byte-identical — same SHA256 — and
# redistribution is permitted by Algencan's GPL-2.0-or-later license.
sources = [
    ArchiveSource(
        "https://github.com/pjssilva/NLPModelsAlgencan.jl/releases/download/algencan-$(version)/algencan-$(version).tgz",
        "ab2a5496e9da49c508f68809cc339f9a604407329be24e3299bd7c21f14d6188",
    ),
]

# Compile the static libalgencan.a (Fortran, no HSL), then wrap it in a shared
# library that exports `c_algencan` — the C entry point that NLPModelsAlgencan.jl
# `ccall`s via `dlsym(..., :c_algencan)`.
script = raw"""
cd ${WORKSPACE}/srcdir/algencan-*

# The bundled top-level Makefile hardcodes CC := gcc-4.9, but only the Fortran
# compiler and the archiver are used by the `algencan` (library) target. Name the
# BinaryBuilder toolchain wrappers explicitly and build position-independent
# objects. NOTE: use literal `gfortran`/`cc`/`ar` (the wrappers on PATH), NOT
# `${AR}` etc. — BinaryBuilder does not export ${AR} in this environment, so
# `AR="${AR}"` would set it empty and break `$(AR) rcs` in the Makefile.
make FC=gfortran CC=cc AR=ar \
     FFLAGS="-O3 -ffree-form -fPIC" CFLAGS="-O3 -fPIC"

mkdir -p "${libdir}"

# Turn the static archive into a shared library, forcing every object (and thus
# the c_algencan symbol) to be included, and link the Fortran runtime.
# ${libdir} already resolves to bin/ on Windows, so the DLL lands in the right
# place with no special-casing of the output path.
if [[ "${target}" == *-apple-* ]]; then
    # macOS: -all_load pulls every object (and thus c_algencan) from the archive.
    ${FC} -shared -o "${libdir}/libalgencan.${dlext}" \
        -Wl,-all_load lib/libalgencan.a -lgfortran
elif [[ "${target}" == *-mingw* ]]; then
    # Windows: emit a DLL, pull in every object, and export all symbols so
    # c_algencan is visible to dlopen/dlsym (mingw auto-exports, but be explicit).
    ${FC} -shared -o "${libdir}/libalgencan.${dlext}" \
        -Wl,--whole-archive lib/libalgencan.a -Wl,--no-whole-archive \
        -Wl,--export-all-symbols -lgfortran
else
    # Linux/BSD: --whole-archive is the GNU-ld equivalent of macOS -all_load.
    ${FC} -shared -o "${libdir}/libalgencan.${dlext}" \
        -Wl,--whole-archive lib/libalgencan.a -Wl,--no-whole-archive -lgfortran
fi

install_license license.txt
"""

# Pure Fortran (GPL-2.0-or-later), no external deps beyond libgfortran, so build
# for every platform Julia supports, Windows included (see the mingw branch in
# the script for how the DLL exports c_algencan).
platforms = supported_platforms()

# libalgencan links libgfortran, whose ABI breaks across GCC major versions, so
# each tarball must be tagged with the libgfortran version it binds to —
# otherwise Pkg hands Julia a mismatched build and the library fails to dlopen.
# Today this expands to libgfortran5 only, which is what every Julia >= 1.6
# (our julia_compat) ships; older ABIs no longer have CompilerSupportLibraries
# artifacts to bind against.
platforms = expand_gfortran_versions(platforms)

# libalgencan.${dlext} exporting the c_algencan entry point.
#
# `dont_dlopen=true` is deliberate and load-bearing for the consumer: Algencan is
# Fortran code with unsafe common blocks, so NLPModelsAlgencan.jl dlopen's the
# library and dlclose's it around every solve to guarantee a clean global state.
# A JLL that dlopen's at __init__ would pin the library in memory and defeat
# that, so this one only hands out the path.
products = [
    LibraryProduct("libalgencan", :libalgencan; dont_dlopen=true),
]

dependencies = [
    # Provides the shared libgfortran that libalgencan links against at runtime.
    Dependency("CompilerSupportLibraries_jll"),
]

# If a very old default gfortran mis-handles the legacy FORMAT strings in
# fparam.f90, pin a newer toolchain by adding e.g. `preferred_gcc_version = v"8"`
# to the build_tarballs call below.
build_tarballs(ARGS, name, version, sources, script, platforms, products,
               dependencies; julia_compat = "1.6")
