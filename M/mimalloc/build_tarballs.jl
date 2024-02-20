# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mimalloc"
version = v"2.1.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/microsoft/mimalloc.git",
              "43ce4bd7fd34bcc730c1c7471c99995597415488"),
]

# Bash recipe for building across all platforms
script = raw"""
if [[ "${target}" == *-linux-musl* ]]; then
    # Musl doesn't support init-exec TLS
    CMAKE_FLAGS=(-DMI_LOCAL_DYNAMIC_TLS=ON) 
fi
cd $WORKSPACE/srcdir/mimalloc/
mkdir -p build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DMI_BUILD_OBJECT=OFF \
    -DMI_INSTALL_TOPLEVEL=ON \
    -DMI_BUILD_TESTS=OFF \
    -DMI_OVERRIDE=OFF \
    "${CMAKE_FLAGS}" \
    ..
make -j ${nproc}
make -j ${nproc} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmimalloc", :libmimalloc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"6.1.0")
