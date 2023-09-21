# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SPRAL"
version = v"2023.09.07"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ralna/spral.git", "04133cdacbc35c868ef8e3b5eb63ee76715625d4")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/spral

if [[ "${target}" == *mingw* ]]; then
  LBT="-lblastrampoline-5"
else
  LBT="-lblastrampoline"
fi

if [[ "${target}" == *-freebsd* ]] || [[ "${target}" == *-apple-* ]]; then
    CC=gcc
    CXX=g++
fi

./autogen.sh
mkdir build
cd build
export CFLAGS="-O3 -fPIC"
export CXXFLAGS="-O3 -fPIC"
export FFLAGS="-O3 -fPIC"
export FCFLAGS="-O3 -fPIC"
../configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-blas="-L${libdir} ${LBT}" --with-lapack="-L${libdir} ${LBT}" \
    --with-metis="-L${libdir} -lmetis" --with-metis-inc-dir="${includedir}"
make
gfortran -fPIC -shared $(flagon -Wl,--whole-archive) libspral.a $(flagon -Wl,--no-whole-archive) -lgomp ${LBT} -lhwloc -lmetis -lstdc++ -o ${libdir}/libspral.${dlext}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libspral", :libspral),
    ExecutableProduct("spral_ssids", :spral_ssids)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="METIS_jll", uuid="d00139f3-1899-568f-a2f0-47f597d42d70")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
    Dependency(PackageSpec(name="Hwloc_jll", uuid="e33a78d0-f292-5ffc-b300-72abe9b543c8")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9.1.0", julia_compat="1.9")
