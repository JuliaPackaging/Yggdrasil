# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SDPLR"
version = v"1.0.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://sburer.github.io/files/SDPLR-1.03-beta.zip", "f1f945734f72e008fd7be8544b27341b179292c3304226563d9c0f6cf503b2eb")
]

# Bash recipe for building across all platforms
# Even if the `Makefile` specifies `-o ../sdplr`,
# On Windows with `libgfortran5`, `.exe` is added.
# On Windows with `libgfortran3` or `libgfortran4`, nothing is added though.
# so we try both
script = raw"""
cd $WORKSPACE/srcdir/SDPLR*
make CFLAGS="-O3 -fPIC" LAPACK_LIB=-lopenblas BLAS_LIB=
${CC} -O3 -fPIC -shared -Llib -o libsdplr.${dlext} source/*.o -lgsl -lopenblas -lgfortran -lm
for executable in sdplr sdplr${exeext}
do
    if [[ -f ${executable} ]]; then
        install -Dvm 755 ${executable} "${bindir}/sdplr${exeext}"
    fi
done
install -Dvm 755 libsdplr.${dlext} "${libdir}/libsdplr.${dlext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("sdplr", :sdplr),
    LibraryProduct("libsdplr", :libsdplr),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Use GCC v6 to fix OpenMP issues on PowerPC
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6", julia_compat="1.6")
