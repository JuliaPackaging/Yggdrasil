# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "isa_l"
version = v"2.31"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/intel/isa-l.git", "bd226375027899087bd48f3e59b910430615cc0a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/isa-l/
./autogen.sh
# Checks from macros `AC_FUNC_MALLOC` and `AC_FUNC_REALLOC` may fail when cross-compiling,
# which can cause configure to remap `malloc` and `realloc` to replacement functions
# `rpl_malloc` and `rpl_realloc`, which will cause a linking error.  For more information,
# see https://stackoverflow.com/q/70725646/2442087
export ac_cv_func_malloc_0_nonnull=yes
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# i686 not supported
filter!(p -> arch(p) != "i686", platforms)
# YASM v1.3.0 (latest stable version as of 2023-05-22) doesn't seem to
# understand AVX512 opcodes.
# See https://github.com/intel/isa-l/issues/285
filter!(!Sys.iswindows, platforms)
# Apple Aarch64 build fails - this should be fixed in the next release
# https://github.com/intel/isa-l/issues/276
# Compilation for aarch64 Darwin fails with error
#     /tmp/crc16_t10dif_pmull-69b5ed.s:209:9: error: unknown AArch64 fixup kind!
#             ldr q_fold_const, fold_constant
#             ^
#     make[1]: *** [Makefile:3623: crc/aarch64/crc16_t10dif_pmull.lo] Error 1
filter!(p -> !(Sys.isapple(p) && arch(p) == "aarch64"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libisal", :libisal),
    ExecutableProduct("igzip", :igzip)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec(name="NASM_jll", uuid="08ca2550-6d73-57c0-8625-9b24120f3eae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")
