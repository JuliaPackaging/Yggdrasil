using BinaryBuilder, Pkg

name = "MSTM"
version = v"4.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/dmckwski/MSTM.git", "12cdb0a45a60e47387cceaa217e2376767826d0e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/MSTM.git/code
mpifort -O2 mpidefs-parallel.f90 mstm-intrinsics.f90 mstm-v4.0.f90 -o mstm
cp mstm ${WORKSPACE}/destdir/bin/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(filter!(!Sys.iswindows, supported_platforms(; experimental=true)))

# The products that we will ensure are always built
products = [
    ExecutableProduct("mstm", :mstm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="MPICH_jll", uuid="7cb0a576-ebde-5e09-9194-50597f1243b4"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
```
