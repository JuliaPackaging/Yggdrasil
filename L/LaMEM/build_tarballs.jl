# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LaMEM"
version = v"1.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://bkaus@bitbucket.org/bkaus/lamem.git", 
    "1fb9c28ada1cd095e1b3c70c8478e1b537150d9f")
]

# Bash recipe for building across all platforms
script = raw"""

# Create required directories
mkdir $WORKSPACE/srcdir/lamem/bin
mkdir $WORKSPACE/srcdir/lamem/bin/opt
mkdir $WORKSPACE/srcdir/lamem/dep
mkdir $WORKSPACE/srcdir/lamem/dep/opt
mkdir $WORKSPACE/srcdir/lamem/lib
mkdir $WORKSPACE/srcdir/lamem/lib/opt

cd $WORKSPACE/srcdir/lamem/src
export PETSC_OPT=${libdir}/petsc/double_real_Int32/
ln -s  ${PETSC_OPT}/lib/libpetsc_double_real_Int32.${dlext} ${PETSC_OPT}/lib/libpetsc.${dlext}
make mode=opt all -j${nproc}

cd  $WORKSPACE/srcdir/lamem/bin/opt

# On some windows versions it automatically puts the .exe extension; on others not. 
# this deals with that
if [[ -f LaMEM ]]
then
    mv LaMEM LaMEM${exeext}
fi

cp LaMEM${exeext} $WORKSPACE/srcdir/lamem/
cp LaMEM${exeext} $WORKSPACE/srcdir
cd $WORKSPACE/srcdir/lamem

# Install binaries
install -Dvm 755 LaMEM* "${bindir}/LaMEM${exeext}"

# Install license
install_license LICENSE

exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms(exclude=[Platform("i686", "windows"),
                                                                  Platform("i686", "linux"; libc = "musl")]))

# The products that we will ensure are always built
products = [
    ExecutableProduct("LaMEM", :LaMEM)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="PETSc_jll", uuid="8fa3689e-f0b9-5420-9873-adf6ccf46f2d")),
    Dependency("MPICH_jll"; platforms=filter(!Sys.iswindows, platforms)),
    Dependency("MicrosoftMPI_jll"; platforms=filter(Sys.iswindows, platforms)),
    Dependency("CompilerSupportLibraries_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"10.2.0")
