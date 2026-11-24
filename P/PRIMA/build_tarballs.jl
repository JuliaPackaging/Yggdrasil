# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PRIMA"
version = v"0.7.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/libprima/prima.git", "af58422ee307f6401a560454c696f229ae8e9bdf")
]

# Bash recipe for building across all platforms
script = raw"""
cd prima

# PRIMA passes nested (internal) procedures as actual arguments, which gfortran implements
# with trampolines on the stack by default. This marks the libraries as requiring an
# executable stack (`GNU_STACK RWE`), and glibc >= 2.41 refuses to `dlopen` such libraries
# ("cannot enable executable stack as shared object requires: Invalid argument").
# GCC >= 14 can allocate the trampolines on the heap instead, so the stack stays
# non-executable. The required runtime support in libgcc_s is only available on
# x86_64 and aarch64 Linux.
FFLAGS=()
if [[ "${target}" == x86_64-linux-gnu* || "${target}" == aarch64-linux-gnu* ]] && [[ "${bb_full_target}" == *libgfortran5* ]]; then
    FFLAGS+=(-ftrampoline-impl=heap)
fi

cmake -S . -B build -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_Fortran_FLAGS="${FFLAGS[*]}"
cmake --build build --target install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)
platforms = filter(p -> libgfortran_version(p) != v"3", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libprimac", :libprimac),
    LibraryProduct("libprimaf", :libprimaf)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
# GCC 14 is needed for `-ftrampoline-impl=heap`. The resulting libraries need
# `__gcc_nested_func_ptr_{created,deleted}@GCC_14.0.0` from libgcc_s, which is only
# shipped with Julia >= 1.12 (via CompilerSupportLibraries_jll).
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.12", preferred_gcc_version=v"14")
