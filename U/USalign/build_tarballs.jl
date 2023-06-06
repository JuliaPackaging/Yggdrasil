# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "USalign"
version = v"0.0.1" # the source repository does not contain any official releases (06/06/2023)

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pylelab/USalign.git", "8d968e0111ca275958f209d76b1cd10598864a34")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd USalign
sed -i 's/\bA0\b/A0_var/g' *.h *.cpp
sed -i 's/\bB0\b/B0_var/g' *.h *.cpp
sed -i 's/\bC0\b/C0_var/g' *.h *.cpp
sed -i 's/\bD0\b/D0_var/g' *.h *.cpp
g++ -O3 -lm -o USalign USalign.cpp
cp USalign ${prefix}/
"""
# The -ffast-math flag was removed from the suggested compilation command as required by BinaryBuilder.
# The -static flag was removed to support macOS aarch64 and x86_64.
# The sed statements are needed to support Linux powerpc64le {libc=glibc}.

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("USalign", :USalign)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
