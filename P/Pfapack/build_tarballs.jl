# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Pfapack"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/xrq-phys/Pfapack.git", "0c71536b9641a0c8f4da67b373e3d4d5514561ab")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd Pfapack

cmake fortran \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release
make -j${nproc} VERBOSE=1
make install

# Manual conversion from static to dynamic lib.
# Avoid linking libgfortran (these .f files make no reference to Fortran libs.)
cc -shared -Wl,-force_load,${prefix}/lib/libpfapack.a \
    -o ${libdir}/libpfapack.${dlext} \
    -L${libdir} -lblastrampoline -lm

# Copy license file
install_license LapackLicence
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# No need to expand Fortran version since there code make no call to
# standard Fortran libraries
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libpfapack", :libpfapack)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.7")
