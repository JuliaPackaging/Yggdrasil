# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "JIL"
version = v"0.1.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://git.renater.fr/anonscm/git/jil/jil.git", "ab56a4be6c37fce27b87b7867865f71dba035d55")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/jil/
./bootstrap.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
cd doc
apk add doxygen
make function_docs_csv
cp build/csv/jil_function_docs.csv ${prefix}/jil_function_docs.csv
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    # We are generating machine code at runtime, and this is implemented only
    # for the above platforms so far. More platforms are planned to be
    # supported in the future.
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libjil", :libjil),
    FileProduct("jil_function_docs.csv", :jil_function_docs_csv),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script,
               platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"9")
