# Note: This file is for use with BinaryBuilder.jl to create libsemigroups_jll
# See https://docs.binarybuilder.org for documentation

using BinaryBuilder, Pkg

name = "libsemigroups"
version = v"3.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/libsemigroups/libsemigroups.git",
              "6b63b74b37ad8d5fe0be82b3225e048d95b3eb2c"),  # v3.4.0
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libsemigroups

# Generate configure script
./autogen.sh
export CPPFLAGS="-I${prefix}/include"

# Configure with vendored dependencies (simplifies cross-compilation)
# Disable HPCombi on non-x86_64 platforms (requires AVX instructions)
HPCOMBI_FLAG=""
if [[ "${target}" != x86_64-* ]]; then
    HPCOMBI_FLAG="--disable-hpcombi"
fi

# switch back to ld on macos to avoid errors:
if [[ "${target}" == *apple* ]]; then
  export LDFLAGS="-fuse-ld=ld"
fi

./configure --prefix=${prefix} \
            --build=${MACHTYPE} \
            --host=${target} \
            --enable-shared \
            --disable-static \
            ${HPCOMBI_FLAG}

# Build and install (V=1 for verbose link commands)
make V=1 -j${nproc}
make install
"""

# These are the platforms we will build for by default
platforms = supported_platforms()

# Filter out platforms that don't support C++17 well
platforms = expand_cxxstring_abis(platforms)

# Build for all supported platforms
# platforms = filter(p -> arch(p) == "x86_64" && Sys.islinux(p), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsemigroups", :libsemigroups),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For the C++ compiler
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll")),
]

# Build the tarballs, and possibly a `build.jl` as well
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.7",
               preferred_gcc_version=v"10")
