# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
name = "Dalton"
version = v"2020.1"

# Collection of sources required to build imagemagick
sources = [
    GitSource("https://gitlab.com/dalton/dalton/", "9d7c5e435b75a9695d5ac8714121d12e6486149f")
]

# Bash recipe for building across all platforms
script = raw"""
git submodule update --init --recursive
# remove bad flags
function traverse() {
    for file in "$1"/*; do
        if [ ! -d "${file}" ] ; then
            sed -i -E 's/ \-ffast\-math| \-march=native| \-Ofast| \-mtune=native//g' "${file}"
        else
            traverse "${file}"
        fi
    done
}
traverse .

# if [[ ${nbits} == 32 ]]; then
    export LBT_DEFAULT_LIBS="${libdir}/libopenblas.${dlext}"
    ./setup --blas="${LBT_DEFAULT_LIBS}" --lapack="${libdir}/liblapack.${dlext}" --prefix="${prefix}"
    # ./setup --blas="${libdir}/libblastrampoline.${dlext}" --lapack="${libdir}/liblapack.${dlext}" --prefix="${prefix}"
# else
#     export LBT_DEFAULT_LIBS="${libdir}/libopenblas64_.${dlext}"
#     ./setup --blas="${LBT_DEFAULT_LIBS}" --lapack="${libdir}/liblapack.${dlext}" --prefix="${prefix}" --int64
#     # ./setup --blas="${libdir}/libblastrampoline.${dlext}" --lapack="${libdir}/liblapack.${dlext}" --prefix="${prefix}" --int64
# fi
cd build
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("dalton", :dalton, "dalton"),
    ExecutableProduct("dalton.x", :dalton_x, "dalton"),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("LAPACK_jll"),
    Dependency("OpenBLAS32_jll"),
    # Dependency("libblastrampoline_jll"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6"
)
