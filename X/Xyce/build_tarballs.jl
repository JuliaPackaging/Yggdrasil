# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Xyce"
version = v"7.7"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Xyce/Xyce.git", "4d3ddea894689560ab68d1a65a42ef585818231c")
]

# Bash recipe for building across all platforms
script = raw"""
# We need a special TMPDIR so that we don't fill up `/tmp`, which is of a limited size in the build environment.
export TMPDIR=${WORKSPACE}/tmpdir
mkdir ${TMPDIR}

cd ${WORKSPACE}/srcdir/Xyce
update_configure_scripts --reconf

# Link aganst LBT for BLAS needs
if [[ "${target}" == *-mingw* ]]; then
    BLAS_NAME=blastrampoline
else
    BLAS_NAME=blastrampoline
fi

./bootstrap
mkdir buildx
cd buildx
../configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --enable-shared --disable-mpi \
    LDFLAGS="-L${libdir} -l${BLAS_NAME}" \
    CPPFLAGS="-I/${includedir} -I/usr/include"
make -j${nprocs}
make install

install_license ${WORKSPACE}/srcdir/Xyce/COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

platforms = supported_platforms()

platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)

# Exclude some platforms that trigger internal compiler errors
platforms = filter(platforms) do p
    return !(arch(p) == "aarch64" && os(p) == "linux" && p["libgfortran_version"] ∈ ("3.0.0", "4.0.0"))
end

# The products that we will ensure are always built
products = [
    LibraryProduct("libxyce", :libxyce),
    ExecutableProduct("Xyce", :Xyce)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("flex_jll"),
    Dependency(PackageSpec(name="Trilinos_jll", uuid="b6fd3212-6f87-5999-b9ea-021e9cd21b17")),
    Dependency(PackageSpec(name="SuiteSparse_jll", uuid="bea87d4a-7f5b-5778-9afe-8cc45184846c"); compat="7.5.1"),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"); compat="5.8.0"),
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8", julia_compat="1.11.0")
