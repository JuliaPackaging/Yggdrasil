using BinaryBuilder

name = "SPRAL"
version = v"0.1.0"

## Sources
sources = [
    GitSource("https://github.com/lanl-ansi/spral.git", "3842fffd5b16f0bf85be6f4b2832816ac4405763"), # master
#    GitSource("https://github.com/lanl-ansi/Ipopt.git", "78a05e2b9138074682a057297b61524f7cb32b53"), # master
]

script = raw"""
cd ${WORKSPACE}/srcdir
# Compile METIS
cd ThirdParty-Metis && ./get.Metis
mkdir build
cd build
../configure --prefix=${PWD}
make && make install
export METISDIR=${PWD}
# Install Dependenices
# TODO: FIX 
# sudo apt-get install hwloc libhwloc-dev
# sudo apt install libopenblas-dev
if [[ "${nbits}" == 64 ]] && [[ "${target}" != aarch64* ]]; then
    OPENBLAS="${libdir}/libopenblas64_.${dlext}"
else
    OPENBLAS="${libdir}/libopenblas.${dlext}"
fi
# ===== BUILD SPRAL =====
# Follow the instruction: https://github.com/lanl-ansi/spral/blob/master/COMPILE.md
cd ${WORKSPACE}/srcdir
cd spral
mkdir build
./autogen.sh # If compiling from scratch.
#CFLAGS=-fPIC CPPFLAGS=-fPIC CXXFLAGS=-fPIC FFLAGS=-fPIC \
#    FCFLAGS=-fPIC ./configure --prefix=${PWD}/build \
#    --with-blas="-lopenblas" --with-lapack="-llapack" \
#    --with-metis="-L${METISDIR}/lib -lcoinmetis" \
#    --with-metis-inc-dir="-I${METISDIR}/include/coin-or/metis"
./autogen.sh # If compiling from scratch.
CFLAGS=-fPIC CPPFLAGS=-fPIC CXXFLAGS=-fPIC FFLAGS=-fPIC FCFLAGS=-fPIC \
    ./configure --prefix=${PWD}/build \
    --with-blas="-L${libdir} -lopenblas" --with-lapack="-L${libdir} -lopenblas" \
    --with-metis="-L${libdir} -lmetis" \
    --with-metis-inc-dir="-I${prefix}/include"
make && make install

# USAGE
export SPRALDIR=${PWD}/build
export OMP_CANCELLATION=TRUE
export OMP_NESTED=TRUE
export OMP_PROC_BIND=TRUE

# ===== BUILD IPOPT =====
# Follow the instruction: https://github.com/lanl-ansi/Ipopt/blob/master/COMPILE.md
#cd ${WORKSPACE}/srcdir/Ipopt
#mkdir build
#cd build
#../configure --prefix=${PWD} --with-spral="-L${SPRALDIR}/lib -L${METISDIR}/lib \
#    -lspral -lgfortran -lhwloc -lm -lcoinmetis "${OPENBLAS}" -lstdc++ -fopenmp" \
#    --with-lapack-lflags="-llapack -lopenblas"
#make && make install
"""

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
#     LibraryProduct("libipopt", :libipopt),
     LibraryProduct("spral_ssids", :spral_ssids)
]

# Dependencies that must be installed before this package can be built
dependencies = Product[
    Dependency("OpenBLAS_jll"),
    Dependency("Hwloc_jll"),
    BuildDependency(PackageSpec(; name = "METIS_jll",
                                uuid = "d00139f3-1899-568f-a2f0-47f597d42d70",
                                version = v"4.0.3")),
#     Dependency("CompilerSupportLibraries_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
