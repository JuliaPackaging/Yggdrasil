using BinaryBuilder, Pkg

name = "Octave"
version = v"9.4.0" 

# Collection of sources required to build Octave
sources = [
   ArchiveSource("https://ftpmirror.gnu.org/octave/octave-$(version).tar.gz",
                  "da9481205bfa717660b7d4a16732d8b2d58aadceab4993d41242a8e2848ea6c1"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/octave*

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

# build on all supported platforms
platforms = supported_platforms()
#filter!(!Sys.isfreebsd, platforms)
#filter!(p -> arch(p) != "riscv64", platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("octave-$version", :octave),
    ExecutableProduct("octave-cli-$version", :octave_cli),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("flex_jll"),
    HostBuildDependency("Bison_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"),
               v"5.12.0";  # build version
               compat="5.8.0"),
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
               julia_compat="1.8", clang_use_lld=false, preferred_gcc_version=v"10")
