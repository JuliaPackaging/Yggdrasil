# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "bwamem2"
version = v"2.2.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/bwa-mem2/bwa-mem2/releases/download/v$(version)/Source_code_including_submodules.tar.gz", "9b001bdc7666ee3f14f3698b21673714d429af50438b894313b05bc4688b1f6d")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/bwa-mem2-*/ext/safestringlib/
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
cd ../../../
make -j${nproc}
install -Dvm 755 "bwa-mem2${exeext}" "${bindir}/bwa-mem2${exeext}"
install -Dvm 755 "bwa-mem2.avx${exeext}" "${bindir}/bwa-mem2.avx${exeext}"
install -Dvm 755 "bwa-mem2.avx2${exeext}" "${bindir}/bwa-mem2.avx2${exeext}"
install -Dvm 755 "bwa-mem2.avx512bw${exeext}" "${bindir}/bwa-mem2.avx512bw${exeext}"
install -Dvm 755 "bwa-mem2.sse41${exeext}" "${bindir}/bwa-mem2.sse41${exeext}"
install -Dvm 755 "bwa-mem2.sse42${exeext}" "${bindir}/bwa-mem2.sse42${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl")
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("bwa-mem2.sse41", :bwamem2_sse41),
    ExecutableProduct("bwa-mem2.avx512bw", :bwamem2_avx512bw),
    ExecutableProduct("bwa-mem2.sse42", :bwamem2_sse42),
    ExecutableProduct("bwa-mem2.avx", :bwamem2_avx),
    ExecutableProduct("bwa-mem2.avx2", :bwamem2_avx2),
    ExecutableProduct("bwa-mem2", :bwamem2)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6.1.0")
