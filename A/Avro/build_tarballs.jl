# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Avro"
version = v"1.11.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/apache/avro.git",
              "c21a60943e5d1f9375d295809876b7b6dd4d58ae"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/avro/lang/c/
atomic_patch -p3 ${WORKSPACE}/srcdir/patches/avro-windows.patch
cmake -B build \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DTHREADSAFE=true \
      -DBUILD_TESTING=OFF
cmake --build build --parallel ${nproc}
cmake --install build

# Delete static library
rm ${prefix}/lib/libavro.a
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libavro", :libavro)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Jansson_jll", uuid="83cbd138-b029-500a-bd82-26ec0fbaa0df"); compat="2.14.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
