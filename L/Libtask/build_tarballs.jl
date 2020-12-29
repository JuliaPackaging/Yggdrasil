# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

julia_version = v"1.5.1"

name = "Libtask"
version = v"0.4.2"

# Collection of sources required to build Libtask
sources = [
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
# create output directory
mkdir -p "${libdir}"

# compile library
cd "${WORKSPACE}/srcdir/"

CFLAGS="-I${includedir} -I${includedir}/julia -O2 -shared -std=gnu99 -fPIC"
if [[ "${target}" == i686-* ]]; then
  CFLAGS="${CFLAGS} -march=pentium4"
fi
if [[ "${target}" == *-mingw* ]]; then
  CFLAGS="${CFLAGS} -Wl,--export-all-symbols"
elif [[ "${target}" == *-linux-* ]]; then
  CFLAGS="${CFLAGS} -Wl,--export-dynamic"
fi

LDFLAGS="-L${libdir} -ljulia"
if [[ "${target}" == *-mingw* ]]; then
  LDFLAGS="${LDFLAGS} -lopenlibm"
fi

$CC $CFLAGS $LDFLAGS task.c -o "${libdir}/libtask_julia.${dlext}"

# install license
install_license LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = libjulia_platforms(julia_version)

# The products that we will ensure are always built
products = [
    LibraryProduct("libtask_julia", :libtask_julia),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="libjulia_jll", version=julia_version)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "~$(julia_version.major).$(julia_version.minor)",
               lock_microarchitecture = false)
