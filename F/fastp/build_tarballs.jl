# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "fastp"
version = v"0.23.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/intel/isa-l.git", "2bbce31943289d5696bcf2a433124c50928226a2"),
    GitSource("https://github.com/ebiggers/libdeflate.git", "02dfa32da3ee3982c66278e714d2e21276dfb67b"),
    GitSource("https://github.com/OpenGene/fastp.git", "ca559a71feed94e74ea449e7567d0506de48dea4"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd isa-l/
./autogen.sh 
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
cd ../libdeflate/
cmake --install-prefix "${prefix}" -B build
cmake --build build
cmake --install build
cd ../fastp/
make
cp "fastp${exeext}" "${bindir}/fastp${exeext}"
mkdir -p "${prefix}/share/licenses/fastp/"
cp ./LICENSE "${prefix}/share/licenses/fastp/"
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl")
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("fastp", :fastp)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="NASM_jll", uuid="08ca2550-6d73-57c0-8625-9b24120f3eae"))
    Dependency(PackageSpec(name="YASM_jll", uuid="997772c2-56d0-5ccd-9329-3f55f14e5768"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")
