# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "booster"
version = v"0.1.2"

# Collection of sources required to build SFML
sources = [
    GitSource("https://github.com/evolbioinfo/booster.git", "a5f5044b192db7ab5572f44ef46abaea007f5ce9")
]

# Bash recipe for building across all platforms
script = raw"""
# compile booster
cd ${WORKSPACE}/srcdir/booster/src
make -j${nproc} CC=${CC} CFLAGS_OMP="-Wall -g -fopenmp"

# move to bindir
install -Dvm 755 "booster" "${bindir}/booster${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("booster", :booster),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
    Dependency("OpenMPI_jll", v"4.1.2"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
