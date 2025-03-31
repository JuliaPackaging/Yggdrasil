using BinaryBuilder, Pkg

name = "Octave"
version = v"9.4.0"

# Collection of sources required to build Octave
sources = [
  ArchiveSource("https://ftpmirror.gnu.org/octave/octave-$(version).tar.gz",
                "da9481205bfa717660b7d4a16732d8b2d58aadceab4993d41242a8e2848ea6c1"),
  DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/octave*

atomic_patch -p0 ../patches/freebsd_sig_atomic_t.patch

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
"""

platforms = supported_platforms()
# Disable RISC-V
filter!(p -> arch(p) != "riscv64", platforms)
platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)
# Disable old libgfortran builds - only use libgfortran5
filter!(p -> !(any(libgfortran_version(p) .== (v"4.0.0", v"3.0.0"))), platforms)

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
    Dependency("libblastrampoline_jll"; compat="5.11.0"),
    Dependency("OpenBLAS32_jll"),
    Dependency("SuiteSparse32_jll"),
    Dependency("Arpack32_jll"),
    Dependency("Sundials32_jll"),
    Dependency("QRupdate_ng_jll"),
    Dependency("CXSparse_jll"; compat="400.400.100"),
    Dependency("PCRE2_jll"),
    Dependency("Readline_jll"),
    Dependency("Libiconv_jll"),
    Dependency("Zlib_jll"),
    Dependency("Bzip2_jll"),
    Dependency("FFTW_jll"),
    Dependency("GLPK_jll"),
    Dependency("GMP_jll"; compat="6.2"),
    Dependency("LibCURL_jll"; compat="7.73.0,8"),
    Dependency("Qhull_jll"),
    Dependency("HDF5_jll"),
    Dependency("rapidjson_jll"),
    Dependency("libsndfile_jll"),
    Dependency("GraphicsMagick_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", clang_use_lld=false, preferred_gcc_version=v"10")
