# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "JIL"
version = v"0.1.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://git.renater.fr/anonscm/git/jil/jil.git", "9f4f67151891a4bd082b36a73604eb660d83806a"; tag="$(version)")
]

# Bash recipe for building across all platforms
script = raw"""
apk add doxygen # TODO: Replace by HostBuildDependency("Doxygen_jll") when the version becomes supported.
cd ${WORKSPACE}/srcdir/jil/
cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
cd doc
cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix}
cmake --build build --target function_docs_csv
cmake --install build
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
    FileProduct("share/jil/jil_function_docs.csv", :jil_function_docs_csv),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(Sys.islinux, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script,
               platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"9")
