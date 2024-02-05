# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "sox"
version = v"14.4.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/chirlu/sox.git", "45b161d73ec087a8e003747b1aed07cd33589bca")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sox/
if [[ "${target}" != *-apple-darwin* ]]; then # Apply patch from https://github.com/chirlu/sox/pull/2
    sed -i '141s/uint64_t/sox_uint64_t/' src/formats_i.c # Replace uint64_t by sox_uint64_t at line 141
fi
autoreconf -i
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# Musl is unsupported
filter!(p -> libc(p) != "musl", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("sox", :sox)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
