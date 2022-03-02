# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "R"
version = v"4.1.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://cran.r-project.org/src/base/R-4/R-$(version).tar.gz",
                  "2036225e9f7207d4ce097e54972aecdaa8b40d7d9911cd26491fac5a0fab38af"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/R-*
export CPPFLAGS="-I${includedir}"
./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --with-x=no \
    --enable-R-shlib=yes \
    --with-blas="-L${libdir} -lopenblas" \
    --with-lapack \
    r_cv_header_zlib_h=yes \
    r_cv_have_bzlib=yes \
    r_cv_have_lzma=yes \
    r_cv_have_pcre2utf=yes \
    r_cv_have_curl728=yes \
    r_cv_have_curl_https=yes \
    r_cv_size_max=yes \
    r_cv_prog_fc_char_len_t=size_t

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libR", :libR, "lib/R/lib"),
    ExecutableProduct("R", :R),
    ExecutableProduct("Rscript", :Rscript),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Readline_jll"),
    Dependency("Zlib_jll"),
    Dependency("Bzip2_jll"),
    Dependency("XZ_jll"),
    Dependency("PCRE2_jll"),
    Dependency("LibCURL_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Libiconv_jll"),
    Dependency("OpenBLAS32_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
