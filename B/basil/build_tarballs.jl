# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "basil"
version = v"1.8.2"   # upstream calls this 1.8.2g; the suffix is not semver

# Pinned to a maintained fork: it carries a regular-mesh (NOR) regression fix
# that is not present in greg-houseman/basil.
sources = [
    GitSource("https://github.com/wenrongcao/basil.git",
              "3133ea91345bf61ac2d3ef29f7d384dd71ee57d1"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/basil

# Upstream's top-level Makefile is imake-generated and host-specific; we drive
# the hand-written MakeSimple files instead and never invoke imake.
rm -f objs/*.o basilsrc/*.o basilsrc/*.mod sybilsrc/*.o xpoly/*.o
mkdir -p objs bin

# Do NOT add -fallow-argument-mismatch: the default compiler for libgfortran5 is
# GCC 8.1 and that option only exists from GCC 10. The F77 needs no such flag.
FFLAGS="-O2 -std=legacy"
CFLAGS="-O2"

# triangle.c's x87 precision clamp needs fpu_control.h, which is glibc-only.
if [[ "${target}" == *-linux-gnu* ]]; then
    CFLAGS="${CFLAGS} -DLINUX"
fi

# MakeSimple hardcodes -lstdc++; Darwin and FreeBSD use clang with libc++.
if [[ "${target}" == *-apple-darwin* ]] || [[ "${target}" == *freebsd* ]]; then
    CXXLIB="-lc++"
else
    CXXLIB="-lstdc++"
fi

# The solver. CPP is what MakeSimple uses to compile polyutils.cc, and it
# defaults to `gcc`; point it at the real C++ compiler. -DGFORTRAN is consumed
# by the preprocessed basil.F and ignored by the .f compiles.
make -C basilsrc -f MakeSimple -j${nproc} \
    FOR="${FC}" CC="${CC}" CPP="${CXX}" \
    FFLAGS="${FFLAGS} -DGFORTRAN" CFLAGS="${CFLAGS}" LDFLAGS="${CXXLIB}"

# Name the sybilps target explicitly: the default `all` would also build the
# Motif/X11 GUI `sybil`, which we do not ship.
make -C sybilsrc -f MakeSimple -j${nproc} \
    FOR="${FC}" CC="${CC}" FFLAGS="${FFLAGS}" CFLAGS="${CFLAGS}" \
    ../bin/sybilps

# Mesh, inversion and post-processing helpers (single-file Fortran each).
make -C xpoly -f MakeSimple -j${nproc} FOR="${FC}" FFLAGS="${FFLAGS}"

for exe in basil sybilps xpoly polyfix selvect mdcomp basinv circles corotate; do
    install -Dvm755 "bin/${exe}" "${bindir}/${exe}"
done

install_license LICENSE
"""

# Windows is deferred: basil writes gfortran unformatted sequential records
# through relative cwd paths, and that has never been validated there.
platforms = supported_platforms()
filter!(!Sys.iswindows, platforms)
# triangle.c clamps the x87 control word only under -DLINUX (needs the glibc-only
# fpu_control.h) or -DCPU86 (MSVC). On i686+musl neither applies, so its
# exact-arithmetic mesh predicates would run with 80-bit intermediates.
filter!(p -> !(arch(p) == "i686" && libc(p) == "musl"), platforms)
# basil links libgfortran, and polyutils.cc leaves std::string values in the
# binary. Neither expansion adds build jobs (both emit only the new ABIs).
platforms = expand_gfortran_versions(platforms)
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("basil",    :basil),      # the FEM solver
    ExecutableProduct("sybilps",  :sybilps),    # PostScript post-processor
    ExecutableProduct("xpoly",    :xpoly),
    ExecutableProduct("polyfix",  :polyfix),
    ExecutableProduct("selvect",  :selvect),
    ExecutableProduct("mdcomp",   :mdcomp),
    ExecutableProduct("basinv",   :basinv),
    ExecutableProduct("circles",  :circles),
    ExecutableProduct("corotate", :corotate),
]

# libgfortran, libquadmath, libgcc_s, libstdc++
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products,
               dependencies; julia_compat="1.6")
