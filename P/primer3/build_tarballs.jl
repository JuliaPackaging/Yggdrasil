# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "primer3"
version = v"2.6.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/primer3-org/primer3.git",
              "7f9f17d6012f404e83bbf0f931a4d06eb4af465b"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/primer3/src
TESTOPTS=""
if [[ "${target}" == *-mingw* ]]; then
    # Selects the `.exe` names and drops primer3_masker, which needs mmap(2)
    TESTOPTS="--windows"
fi
make -j${nproc} CC="${CC}" CXX="${CXX}" TESTOPTS="${TESTOPTS}"
for exe in primer3_core ntdpal ntthal oligotm amplicon3_core; do
    install -Dvm 755 "${exe}${exeext}" "${bindir}/${exe}${exeext}"
done
if [[ "${target}" != *-mingw* ]]; then
    install -Dvm 755 primer3_masker "${bindir}/primer3_masker"
fi
install_license ../LICENSE LICENSE_GPL3_for_Amplicon3
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms_unix = filter(!Sys.iswindows, platforms)
platforms_windows = filter(Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("primer3_core", :primer3_core),
    ExecutableProduct("ntdpal", :ntdpal),
    ExecutableProduct("ntthal", :ntthal),
    ExecutableProduct("oligotm", :oligotm),
    ExecutableProduct("amplicon3_core", :amplicon3_core),
]
products_unix = [
    ExecutableProduct("primer3_masker", :primer3_masker),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # primer3_core and primer3_masker are linked with libstdc++ and libgcc_s
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
# GCC 5 is the oldest whose default C dialect accepts the C99 for-loop declarations in amplicontm.c
if any(should_build_platform.(triplet.(platforms_windows)))
    build_tarballs(ARGS, name, version, sources, script, platforms_windows, products, dependencies;
                   julia_compat="1.6", preferred_gcc_version=v"5")
end
if any(should_build_platform.(triplet.(platforms_unix)))
    build_tarballs(ARGS, name, version, sources, script, platforms_unix, [products; products_unix], dependencies;
                   julia_compat="1.6", preferred_gcc_version=v"5")
end
