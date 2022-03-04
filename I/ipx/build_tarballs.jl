# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ipx"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ERGO-Code/ipx.git", "234d484ed1813ce1d95e49c2d86da79d2df18f95")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ipx/
ARGS=(CXX="c++" CFLAGS="-std=c++11" BASICLUROOT="$prefix")
if [[ ${target} == *mingw32* ]]; then
    ARGS+=(UNAME="Windows" SO_OPTS="-shared")
else
    ARGS+=(UNAME="$(uname)")
fi
make shared "${ARGS[@]}"
cp lib/* "${libdir}/."
cp include/* "${includedir}/."
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> (Sys.islinux(p) || Sys.isfreebsd(p)) && nbits(p) == 64, supported_platforms(;experimental=true))
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libipx", :libipx)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="basiclu_jll", uuid="5629d00f-ba42-508e-84a8-8193befe9d4f"))
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
    Dependency(PackageSpec(name="LAPACK_jll", uuid="51474c39-65e3-53ba-86ba-03b1b862ec14"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
