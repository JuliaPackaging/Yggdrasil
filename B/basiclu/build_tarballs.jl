# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "basiclu"
version = v"2.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ERGO-Code/basiclu.git", "a2828782151288efa5e2cb2e0c1ac21925ed9db9")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/basiclu/
ARGS=(CC99="cc" CFLAGS="-std=c99" CPPFLAGS="-DBASICLU_NOTIMER")
if [[ ${target} == *mingw32* ]]; then
    ARGS+=(UNAME="Windows")
else
    ARGS+=(UNAME="$(uname)")
fi
make "${ARGS[@]}"
cp lib/* "${libdir}/."
mkdir -p ${includedir}
cp include/* "${includedir}/."
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libbasiclu", :libbasiclu)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
