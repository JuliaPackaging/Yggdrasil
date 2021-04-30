# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SPRAL"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lanl-ansi/spral.git", "5a83fe10178997f89eecc17145b8ca30e4c3e989"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/spral
if [[ "${target}" == *-freebsd* ]] || [[ "${target}" == *-apple-* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/timespec.patch
fi
./autogen.sh
update_configure_scripts
mkdir build
cd build
CFLAGS=-fPIC CPPFLAGS=-fPIC CXXFLAGS=-fPIC FFLAGS=-fPIC FCFLAGS=-fPIC \
    ../configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-blas="-L${libdir} -lopenblas" --with-lapack="-L${libdir} -lopenblas" \
    --with-metis="-L${libdir} -lmetis" --with-metis-inc-dir="${prefix}/include"
make && make install
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
    Dependency(PackageSpec(name="METIS4_jll", uuid="40b5814e-7855-5c9f-99f7-a735ce3fdf8b"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
    Dependency(PackageSpec(name="Hwloc_jll", uuid="e33a78d0-f292-5ffc-b300-72abe9b543c8"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8.1.0")
