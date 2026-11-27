# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

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

# Platforms where we build with `-ftrampoline-impl=heap` (see the script above), which
# requires GCC 14. Keep the default toolchain everywhere else: newer GCCs bring unrelated
# toolchain issues on other platforms (e.g. macOS) that don't benefit from the flag.
# Keep this in sync with the condition in the script.
heap_trampolines(p) = Sys.islinux(p) && libc(p) == "glibc" && arch(p) in ("x86_64", "aarch64") &&
                      libgfortran_version(p) == v"5"
platforms_heap, platforms_other = filter(heap_trampolines, platforms), filter(!heap_trampolines, platforms)

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
# The libraries built with `-ftrampoline-impl=heap` need
# `__gcc_nested_func_ptr_{created,deleted}@GCC_14.0.0` from libgcc_s, which is only
# shipped with Julia >= 1.12 (via CompilerSupportLibraries_jll).
if any(should_build_platform.(triplet.(platforms_heap)))
    build_tarballs(ARGS, name, version, sources, script, platforms_heap, products, dependencies;
                   julia_compat="1.12", preferred_gcc_version=v"14")
end
if any(should_build_platform.(triplet.(platforms_other)))
    build_tarballs(ARGS, name, version, sources, script, platforms_other, products, dependencies;
                   julia_compat="1.12")
end
