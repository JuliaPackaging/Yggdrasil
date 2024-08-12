# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SDPLR"
upstream_version = v"1.0.3"
version_offset = v"0.2.0" # reset to 0.0.0 once the upstream version changes
version = VersionNumber(upstream_version.major * 100 + version_offset.major,
                        upstream_version.minor * 100 + version_offset.minor,
                        upstream_version.patch * 100 + version_offset.patch)

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sburer/sdplr.git", "6866be46ac64aef7043e21dd79f26df83b953280")
]

# Bash recipe for building across all platforms
# Even if the `Makefile` specifies `-o ../sdplr`,
# On Windows with `libgfortran5`, `.exe` is added.
# On Windows with `libgfortran3` or `libgfortran4`, nothing is added though.
# so we try both
script = raw"""
cd $WORKSPACE/srcdir/sdplr
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
