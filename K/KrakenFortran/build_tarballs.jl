using BinaryBuilder, Pkg

name = "KrakenFortran"
version = v"0.1.0"

# Collection of sources compiled in this build
sources = [
    GitSource("https://github.com/vardister/KrakenFortran.jl.git", "5f9a9c0f7e56573fb888bc15cd4b495c49c1c5f6")
]

# Bash recipe for building across all platforms
script = raw"""
# Debug: List what's in srcdir to see the structure
echo "Listing srcdir contents:"
ls -R $WORKSPACE/srcdir

# Find where src_fortran/source actually is
cd $WORKSPACE/srcdir
# Search for the directory and handle potential absence gracefully
FORTRAN_ROOT=$(find . -name "src_fortran" -type d -print -quit)

if [ -z "$FORTRAN_ROOT" ]; then
    echo "Error: Could not find src_fortran directory in the source tree."
    echo "Make sure you have pushed your code to GitHub and are using the correct commit hash."
    exit 1
fi

cd "$FORTRAN_ROOT/source"
mkdir -p build
cd build

# Use the cross-compilers provided by the environment
FFLAGS="-cpp -fPIC -O3 -finline-functions -fno-strength-reduce -fomit-frame-pointer -falign-functions=2"

# Compile all source files in the correct order for modules
gfortran $FFLAGS -c ../krakmod.f90 -o krakmod.o
gfortran $FFLAGS -c ../sdrdrmod.f90 -o sdrdrmod.o
gfortran $FFLAGS -c ../zsecx.f90 -o zsecx.o
gfortran $FFLAGS -c ../zbrentx.f90 -o zbrentx.o
gfortran $FFLAGS -c ../bcimp.f90 -o bcimp.o
gfortran $FFLAGS -c ../kuping.f90 -o kuping.o
gfortran $FFLAGS -c ../sinvitd.f90 -o sinvitd.o
gfortran $FFLAGS -c ../mergev.f90 -o mergev.o
gfortran $FFLAGS -c ../weight.f90 -o weight.o
gfortran $FFLAGS -c ../twersk.f90 -o twersk.o
gfortran $FFLAGS -c ../subtab.f90 -o subtab.o
gfortran $FFLAGS -c ../readin.f90 -o readin.o
gfortran $FFLAGS -c ../errout.f90 -o errout.o
gfortran $FFLAGS -c ../sorti.f90 -o sorti.o
gfortran $FFLAGS -c ../splinec.f90 -o splinec.o
gfortran $FFLAGS -c ../kraken.f90 -o kraken.o

# Link into a shared library
gfortran -shared -o libkraken.${dlext} *.o

# Install the library into the destination
# On Windows, DLLs go into 'bin', on others into 'lib'
if [[ "${target}" == *-mingw* ]]; then
    mkdir -p ${bindir}
    install -m 755 libkraken.${dlext} ${bindir}/libkraken.${dlext}
else
    mkdir -p ${libdir}
    install -m 755 libkraken.${dlext} ${libdir}/libkraken.${dlext}
fi
"""

# These are the platforms we will build for by default
platforms = supported_platforms()
# Filter for platforms that support gfortran
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libkraken", :libkraken)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]


# Build the tarballs, and possibly a samplerepo as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
