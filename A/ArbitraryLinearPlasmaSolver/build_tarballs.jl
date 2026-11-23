# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "ArbitraryLinearPlasmaSolver"
version = v"1.1.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/danielver02/ALPS.git", "220597dad7e94662368c3820f8b8d48b3e825cc2"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd ALPS

# Fix hardcoded BLAS/LAPACK in all Makefile.am files
sed -i 's/-llapack -lblas/$(LAPACK_LIBS) $(BLAS_LIBS)/g' distribution/Makefile.am
sed -i 's/-llapack -lblas/$(LAPACK_LIBS) $(BLAS_LIBS)/g' interpolation/Makefile.am

autoreconf -fi

# Fix EOF handling in interpolation to avoid segfault
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/interpolation-eof.patch"

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-blas="-lblastrampoline" --with-lapack="-lblastrampoline" FC=mpifort
make
make install

# Run tests
if [[ "${target}" == "x86_64-linux-musl" ]]; then
    # strip the unsupported MPI flag before running tests
    sed -i 's/--oversubscribe //g' tests/run_test.sh
    cd tests
    bash ./run_test.sh
fi
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(exclude = Sys.iswindows)
platforms, platform_dependencies = MPI.augment_platforms(platforms)

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("ALPS", :ALPS),
    ExecutableProduct("generate_distribution", :generate_distribution),
    ExecutableProduct("interpolation", :interpolation),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name = "libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"))
    Dependency(PackageSpec(name = "LAPACK_jll", uuid = "51474c39-65e3-53ba-86ba-03b1b862ec14"))
    Dependency(PackageSpec(name = "CompilerSupportLibraries_jll", uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6", preferred_gcc_version = v"9.1.0", augment_platform_block)
