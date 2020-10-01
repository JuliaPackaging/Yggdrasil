# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SARSOP"
version = v"0.96.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/JuliaPOMDP/sarsop.git", "903fa55df637d127c1068700377995ee395475a6")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd sarsop/src
make -j${nprocs} CC=${CC} CXX=${CXX} LINKER=${CXX} DESTDIR=${prefix}
make install DESTDIR=${prefix}
if [[ "${target}" == *mingw* ]]; then
    for file in ${prefix}/bin/*;
    do
        mv $file $file.exe
    done
fi
install_license ${WORKSPACE}/srcdir/sarsop/license/*
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    ExecutableProduct("pomdpsim", :pomdpsim),
    ExecutableProduct("pomdpconvert", :pomdpconvert),
    ExecutableProduct("pomdpeval", :pomdpeval),
    ExecutableProduct("pomdpsol", :pomdpsol),
    ExecutableProduct("polgraph", :polgraph)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
