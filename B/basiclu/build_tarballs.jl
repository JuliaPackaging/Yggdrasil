# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "basiclu"
version = v"2.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ERGO-Code/basiclu.git", "5c882bd2617006d0d1ee6ba3400686da092ecd85"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
if [[ ${target} == *mingw32* ]]; then
    for f in ${WORKSPACE}/srcdir/patches/*.patch; do
        atomic_patch -p1 ${f}
    done
fi
cd basiclu/
if [[ ${target} == *mingw32* ]]; then
    make CC99="cc -std=c99"
elif [[ ${target} == *-apple-* ]] || [[ ${target} == *freebsd* ]]; then
    make CC99="cc -std=c99" -D_DARWIN_C_SOURCE
else
    make CC99="cc -std=c99" LDLIBS="-lm -lrt"
fi
cp -r lib/ $prefix
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
