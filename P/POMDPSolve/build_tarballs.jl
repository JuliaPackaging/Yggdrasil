# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "POMDPSolve"
version = v"5.4.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/JuliaPOMDP/pomdp-solve.git", "9e1e9987e459732c4b435387a346515afcab4e01")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd pomdp-solve/

autoreconf -f -i

./configure --prefix=${prefix} --exec_prefix=${prefix} --build=${MACHTYPE} --host=${target}

make -j${nprocs}

make install

install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),  
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("i686", "windows"),
    Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("pomdp-tools", :pomdptools),
    ExecutableProduct("pomdp-solve", :pomdpsolve),
    ExecutableProduct("pomdp-test", :pomdptest),
    ExecutableProduct("pomdp-fg", :pomdpfg)
]


# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
