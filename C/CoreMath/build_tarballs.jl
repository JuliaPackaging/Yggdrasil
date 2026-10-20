# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CoreMath"
version = v"0.1.0"

commit = "9a10f6e246374437d2dfcf0714fce5ce4254f986"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.inria.fr/core-math/core-math.git", commit),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/core-math*/

# Collect source files for each precision
# binary64: src/binary64/{name}/{name}.c     → cr_{name}(double)
# binary32: src/binary32/{name}/{name}f.c    → cr_{name}f(float)
# binary16: src/binary16/{name}/{name}f16.c  → cr_{name}f16(_Float16)
SRCS=""
for d in src/binary64/*/; do
    fname=$(basename "$d")
    src="$d/${fname}.c"
    [ -f "$src" ] && SRCS="$SRCS $src"
done
for d in src/binary32/*/; do
    fname=$(basename "$d")
    src="$d/${fname}f.c"
    [ -f "$src" ] && SRCS="$SRCS $src"
done
# binary16 requires _Float16 support and compiler-rt intrinsics (__truncsfhf2,
# __extendhfsf2). These are available with GCC >= 12 (Linux) but not with
# the macOS/FreeBSD Clang cross-compiler or MinGW.
if [[ "${target}" == *-linux-* ]]; then
    for d in src/binary16/*/; do
        fname=$(basename "$d")
        src="$d/${fname}f16.c"
        [ -f "$src" ] && SRCS="$SRCS $src"
    done
fi

# On x86_64, enable SSE4.1 so that core-math's roundeven_finite() uses the
# inline roundsd instruction instead of calling roundeven() from libm
# (which doesn't exist on macOS). SSE4.1 is available on all x86_64 CPUs
# that Julia supports.
ARCH_CFLAGS=""
if [[ "${target}" == x86_64-* ]]; then
    ARCH_CFLAGS="-msse4.1"
fi

# Compile all source files into object files
mkdir -p build
for src in $SRCS; do
    fname=$(basename "$src" .c)
    # Rename as_compoundf_special in binary16's compoundf16.c to avoid
    # symbol collision with binary32's compoundf.c (upstream bug: both
    # define this non-static helper with the same name)
    EXTRA=""
    if [[ "$src" == *binary16/compound* ]]; then
        EXTRA="-Das_compoundf_special=as_compoundf16_special"
    fi
    ${CC} ${CFLAGS} -fPIC -O2 ${ARCH_CFLAGS} ${EXTRA} -I. -c "$src" \
        -o "build/${fname}.o" || continue
done

# Link all object files into a shared library
mkdir -p ${libdir}
if [[ "${target}" == *-apple-* ]]; then
    ${CC} -dynamiclib -o ${libdir}/libcoremath.${dlext} build/*.o -lm
else
    ${CC} -shared -o ${libdir}/libcoremath.${dlext} build/*.o -lm
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# core-math uses unsigned __int128 which is unavailable on 32-bit platforms
filter!(p -> nbits(p) == 64, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcoremath", :libcoremath),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
# Requires GCC >= 12 for _Float16 (binary16) support and __builtin_roundeven
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"12")
