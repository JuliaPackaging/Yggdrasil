using BinaryBuilder

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "primer3"
version = v"2.6.1"

sources = [
    GitSource("https://github.com/primer3-org/primer3.git",
              "7f9f17d6012f404e83bbf0f931a4d06eb4af465b"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/primer3/src
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
install_license LICENSE LICENSE_GPL3_for_Amplicon3
"""

platforms = supported_platforms()
platforms_unix = filter(!Sys.iswindows, platforms)
platforms_windows = filter(Sys.iswindows, platforms)

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

dependencies = [
    # primer3_core and primer3_masker link libgcc_s
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isapple, platforms)),
]

# GCC 8 gives the libgfortran5 platform tag, the only one CompilerSupportLibraries_jll ships libgcc_s for.
# GCC 4.8 would also reject the C99 for-loop declarations in amplicontm.c.
if any(should_build_platform.(triplet.(platforms_windows)))
    build_tarballs(ARGS, name, version, sources, script, platforms_windows, products, dependencies;
                   julia_compat="1.6", preferred_gcc_version=v"8")
end
if any(should_build_platform.(triplet.(platforms_unix)))
    build_tarballs(ARGS, name, version, sources, script, platforms_unix, [products; products_unix], dependencies;
                   julia_compat="1.6", preferred_gcc_version=v"8")
end
