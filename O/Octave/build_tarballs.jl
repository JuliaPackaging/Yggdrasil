using BinaryBuilder, Pkg

name = "Octave"
version = v"11.1.0"

# Collection of sources required to build Octave
sources = [
    ArchiveSource("https://ftpmirror.gnu.org/octave/octave-$(version).tar.gz",
                  "c0e7e2c91bc573256431b2cc989290b9bd13851dbadd59d0ac74714f1334b0e6"),
    FileSource("https://github.com/fastfloat/fast_float/releases/download/v8.2.4/fast_float.h",
               "0055d1c392c2ebd9933146d3efcc9a7b98abb45960ecb90fcaadfc00b9be22e6"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/octave*

# Install fast-float header-only library
mkdir ${includedir}/fast_float
cp ../fast_float.h ${includedir}/fast_float

apk add texinfo

export CPPFLAGS="-I${includedir}"
export TMPDIR=${WORKSPACE}/tmpdir
mkdir -p ${TMPDIR}

if [[ "${target}" == *-mingw* ]]; then
    LBT="blastrampoline-5"
else
    LBT="blastrampoline"
fi

# Base configure flags
FLAGS=(
    --prefix="$prefix"
    --build=${MACHTYPE}
    --host="${target}"
    --enable-shared
    --disable-static
    --with-blas="-L${libdir} -l${LBT}"
    --with-lapack="-L${libdir} -l${LBT}"
)

./configure "${FLAGS[@]}"
make -j${nproc}
make install

install_license COPYING
install_license COPYRIGHT.md
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("octave-$version", :octave),
    ExecutableProduct("octave-cli-$version", :octave_cli),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("flex_jll"),
    HostBuildDependency("Bison_jll"),
    HostBuildDependency("gperf_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("libblastrampoline_jll"; compat="5.11.2"),
    Dependency("OpenBLAS32_jll"),
    Dependency("SuiteSparse32_jll"; compat="7.8.3"),
    Dependency("Arpack32_jll"; compat="3.9.1"),
    Dependency("Sundials32_jll"; compat="5.3.0"),
    Dependency("QRupdate_ng_jll"; compat="1.1.5"),
    Dependency("CXSparse_jll"; compat="400.400.100"),
    Dependency("PCRE2_jll"),
    Dependency("Readline_jll"; compat="8.2.13"),
    Dependency("Libiconv_jll"),
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency("Bzip2_jll"; compat="1.0.9"),
    Dependency("FFTW_jll"; compat="3.3.11"),
    Dependency("GLPK_jll"; compat="5.0.1"),
    Dependency("GMP_jll"; compat="6.2.1"),
    Dependency("LibCURL_jll"; compat="7.73.0,8"),
    Dependency("Qhull_jll"; compat="10008.0.1004"),
    Dependency("HDF5_jll"; compat="2.0.0"),
    Dependency("rapidjson_jll"; compat="1.1.1"),
    Dependency("libsndfile_jll"),
    Dependency("GraphicsMagick_jll"; compat="1.3.46"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.10", preferred_gcc_version=v"10")
