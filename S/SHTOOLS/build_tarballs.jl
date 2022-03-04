using BinaryBuilder

# Collection of sources required to build SHTOOLS
name = "SHTOOLS"
version = v"4.9.1"
sources = [
    ArchiveSource("https://github.com/SHTOOLS/SHTOOLS/releases/download/v4.9.1/SHTOOLS-4.9.1.tar.gz",
                  "5c22064f9daf6e9aa08cace182146993aa6b25a6ea593d92572c59f4013d53c2"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SHTOOLS-*

# Patch source code
# Don't use libtool
atomic_patch -p0 $WORKSPACE/srcdir/patches/no-libtool.patch
# Correct C interface for MakeGradientDH (see <https://github.com/SHTOOLS/SHTOOLS/issues/328>)
atomic_patch -p1 $WORKSPACE/srcdir/patches/correct-cMakeGradientDH.patch

# Build and install static libraries
make fortran -j${nproc} F95FLAGS="-fPIC -O3 -std=gnu"
make fortran-mp -j${nproc} F95FLAGS="-fPIC -O3 -std=gnu"
make install PREFIX=${prefix}

# Create shared libraries
# TODO: Do we need to add " | cut -d' ' -f1"?
whole_archive=$(flagon --whole-archive)
if [ -n "${whole_archive}" ]; then
    whole_archive="-Wl,${whole_archive}"
fi
no_whole_archive=$(flagon --no-whole-archive)
if [ -n "${no_whole_archive}" ]; then
    no_whole_archive="-Wl,${no_whole_archive}"
fi
gfortran -shared -o ${libdir}/libSHTOOLS.${dlext} ${whole_archive} ${prefix}/lib/libSHTOOLS.a ${no_whole_archive} -lfftw3 -lopenblas -lm
gfortran -fopenmp -shared -o ${libdir}/libSHTOOLS-mp.${dlext} ${whole_archive} ${prefix}/lib/libSHTOOLS-mp.a ${no_whole_archive} -lfftw3 -lopenblas -lm
"""

platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libSHTOOLS", :libSHTOOLS),
    LibraryProduct("libSHTOOLS-mp", :libSHTOOLS_mp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("FFTW_jll"),
    Dependency("OpenBLAS32_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
