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

# Makes Algencan query HSL's ma57_available at run time instead of deciding at
# compile time, so one binary uses MA57 when a licensed HSL is installed and
# falls back to truncated Newton otherwise. Also drops Algencan's use of
# finfo%pivot, a field only a locally patched MA57 provides.
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/algencan-3.1.1-runtime-hsl.patch

# sources/algencan/Makefile selects the real lssma57.o over the stub when
# hsl_ma57_double.mod is found in HSLSRC. Only that module is linked in, so
# MA86 and MA97 keep their stubs.
mkdir -p hsldetect
ln -s ${prefix}/modules/hsl_ma57_double.mod hsldetect/

make -C sources/algencan lib \
     FC=gfortran AR=ar \
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

# libhsl_subset is linked for the hsl_ma57_double module symbols and for
# ma57_available. The public artifact is a stub, so no licensed code enters the
# build; users with a licence override the artifact.
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
