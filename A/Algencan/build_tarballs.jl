using BinaryBuilder, Pkg

name = "Algencan"
version = v"3.1.1"

# Collection of sources required to complete build
# Mirror of the upstream tarball, which lives at a personal academic URL.
# Byte identical, same SHA256. Algencan is GPL-2.0-or-later.
sources = [
    ArchiveSource(
        "https://github.com/pjssilva/NLPModelsAlgencan.jl/releases/download/algencan-$(version)/algencan-$(version).tgz",
        "ab2a5496e9da49c508f68809cc339f9a604407329be24e3299bd7c21f14d6188",
    ),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/algencan-*

# lssma97.f90 ships with CRLF line endings; normalise them so the patch below
# does not have to carry CRLF context lines.
sed -i 's/\r$//' sources/algencan/lssma97.f90

# Makes Algencan query HSL's maNN_available at run time instead of deciding at
# compile time, so one binary may use MANN when a licensed HSL is installed.
# If MA57 is not available it falls back to truncated Newton. Also drops
# Algencan's use of finfo%pivot, a field only a locally patched MA57 provides.
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/algencan-3.1.1-runtime-hsl.patch

# sources/algencan/Makefile picks the real lssmaNN.o over the stub for each
# solver whose module it finds in HSLSRC. ALGENCAN still prefers MA57, and the
# trust region accepts nothing else; MA86 and MA97 are reachable through the
# specification file.
mkdir -p hsldetect
for m in ma57 ma86 ma97; do
    ln -s ${prefix}/modules/hsl_${m}_double.mod hsldetect/
done

# OPENMPFLAG is defined in the root Makefile, which this call bypasses, so it
# has to be repeated to keep upstream's default.
make -C sources/algencan lib \
     FC=gfortran AR=ar OPENMPFLAG=-fopenmp \
     FFLAGS="-O3 -ffree-form -fPIC -I${prefix}/modules" \
     HSLSRC=${PWD}/hsldetect

mkdir -p "${libdir}"

# Force every object in so that c_algencan survives.
if [[ "${target}" == *-apple-* ]]; then
    ${FC} -shared -o "${libdir}/libalgencan.${dlext}" \
        -Wl,-all_load sources/algencan/libalgencan.a \
        -L${libdir} -L${prefix}/lib -lhsl_subset -lgfortran
elif [[ "${target}" == *-mingw* ]]; then
    ${FC} -shared -o "${libdir}/libalgencan.${dlext}" \
        -Wl,--whole-archive sources/algencan/libalgencan.a -Wl,--no-whole-archive \
        -Wl,--export-all-symbols -L${libdir} -L${prefix}/lib -lhsl_subset -lgfortran
else
    ${FC} -shared -o "${libdir}/libalgencan.${dlext}" \
        -Wl,--whole-archive sources/algencan/libalgencan.a -Wl,--no-whole-archive \
        -L${libdir} -L${prefix}/lib -lhsl_subset -lgfortran
fi

install_license license.txt
"""

platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# dont_dlopen: Algencan keeps state in Fortran common blocks, so consumers load
# and unload the library around each solve.
products = [
    LibraryProduct("libalgencan", :libalgencan; dont_dlopen=true),
]

# libhsl_subset is linked for the hsl_maNN_double module symbols and for the
# maNN_available flags. The public artifact is a stub, so no licensed code
# enters the build; users with a licence override the artifact.
#
# Note for consumers: libhsl_subset is LP64, and Julia registers only an ILP64
# BLAS backend by default, so an LP64 one has to be forwarded to
# libblastrampoline, as HSL.jl and Ipopt.jl do.
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("HSL_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products,
               dependencies; julia_compat = "1.6")
