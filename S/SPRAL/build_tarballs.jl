# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SPRAL"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ralna/spral.git", "186b1c3bb0d3c09640365a1e109aa5c9115e6cf8"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/spral
if [[ "${target}" == *-freebsd* ]] || [[ "${target}" == *-apple-* ]]; then
    CC=gcc
    CXX=g++
fi
./autogen.sh
mkdir build
cd build
CFLAGS=-fPIC CPPFLAGS=-fPIC CXXFLAGS=-fPIC FFLAGS=-fPIC FCFLAGS=-fPIC \
    ../configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-blas="-L${libdir} -lopenblas" --with-lapack="-L${libdir} -lopenblas" \
    --with-metis="-L${libdir} -lmetis" --with-metis-inc-dir="${prefix}/include"
make && make install
cc -shared -fPIC -o "${libdir}/libspral.${dlext}" -Wl,$(flagon --whole-archive) "${prefix}/lib/libspral.a"
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())


# The products that we will ensure are always built
products = [
    ExecutableProduct("spral_ssids", :spral_ssids)
    FileProduct("lib/libspral.a", :libspral_a)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="METIS_jll", uuid="d00139f3-1899-568f-a2f0-47f597d42d70"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
    Dependency(PackageSpec(name="Hwloc_jll", uuid="e33a78d0-f292-5ffc-b300-72abe9b543c8"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9.1.0", julia_compat="1.6")
