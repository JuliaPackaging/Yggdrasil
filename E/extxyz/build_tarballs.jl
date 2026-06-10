# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "extxyz"
version = v"0.4.0"

# Collection of sources required to complete build.
# libcleri is a git submodule of extxyz (the libAtoms fork, which has diverged
# from upstream cesbit/libcleri); GitSource does not fetch submodules, so it is
# included as a second source pinned to the submodule commit and built
# statically into libextxyz, replacing the former libcleri_jll dependency.
sources = [
    GitSource("https://github.com/libAtoms/extxyz",
              "7e3c010be21a99507c16291b48f00cd9ce93f698"),  # v0.4.0
    GitSource("https://github.com/libAtoms/libcleri",
              "d12f5faba985e0f4a04025f84c0e6c1a025a366b"),  # extxyz submodule pin
]

# Bash recipe for building across all platforms.
# Upstream now builds with Meson, but its top-level meson.build is geared to
# producing Python wheels (it requires a Python installation and generates the
# grammar via pyleri at setup time). The standalone shared library target is
# just three C files, so they are compiled directly, mirroring what the old
# Makefile (used by the previous version of this recipe) did.
script = raw"""
cd $WORKSPACE/srcdir/extxyz

# place the vendored libcleri submodule
rm -rf libcleri
cp -r ../libcleri libcleri

# generate the key/value grammar parser sources (extxyz_kv_grammar.c/.h);
# the old Makefile build did the same pip3 install at build time
pip3 install pyleri
cd libextxyz
python3 ../python/extxyz/extxyz_kv_grammar.py

# build the vendored libcleri statically
cd ../libcleri
mkdir -p build
cd build
${CC} -O2 -fPIC -std=c99 -I../inc $(pcre2-config --cflags) -c ../src/*.c
${AR} rcs libcleri.a *.o

# link the shared library
cd ../../libextxyz
mkdir -p ${libdir} ${includedir}
${CC} -O2 -fPIC -std=c99 -shared -o ${libdir}/libextxyz.${dlext} \
    extxyz.c extxyz_kv_grammar.c fast_format.c \
    -I../libcleri/inc $(pcre2-config --cflags) \
    ../libcleri/build/libcleri.a $(pcre2-config --libs8)
cp extxyz.h ${includedir}

install_license ${WORKSPACE}/srcdir/extxyz/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)


# The products that we will ensure are always built
products = [
    LibraryProduct("libextxyz", :libextxyz)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="PCRE2_jll", uuid="efcefdf7-47ab-520b-bdef-62a2eaa19f15")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
