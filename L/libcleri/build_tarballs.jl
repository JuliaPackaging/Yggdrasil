# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libcleri"
version = v"0.12.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/transceptor-technology/libcleri.git",
              "a8a1adc9dcf4e889a4d44c17acb20d74d0c6cfe5"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libcleri/
atomic_patch -p1 ../patches/cc-compiler.patch
export CFLAGS=$(pcre2-config --cflags)
export LDFLAGS=$(pcre2-config --libs8)
make -C Release FN="libcleri.${dlext}"
make -C Release FN="libcleri.${dlext}" install INSTALL_PATH=${prefix}
if [[ "${target}" == *-apple-* ]]; then
    install_name_tool -id @rpath/libcleri.dylib.0 ${libdir}/libcleri.dylib
fi
if [[ "${target}" == *-mingw* ]]; then
    chmod a+x ${prefix}/lib/libcleri.${dlext}
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcleri", :libcleri)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="PCRE2_jll", uuid="efcefdf7-47ab-520b-bdef-62a2eaa19f15"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
