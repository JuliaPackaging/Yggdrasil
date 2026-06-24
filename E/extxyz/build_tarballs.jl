# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "extxyz"
version = v"0.4.4"

# Collection of sources required to complete build.
# libcleri is a git submodule of extxyz (the libAtoms fork, which has diverged
# from upstream cesbit/libcleri); GitSource does not fetch submodules, so it is
# included as a second source pinned to the submodule commit and built
# statically into libextxyz, replacing the former libcleri_jll dependency.
sources = [
    GitSource("https://github.com/libAtoms/extxyz",
              "3d3f9180fd210729bcb603258260c3fa4675f5f9"),  # v0.4.4
    GitSource("https://github.com/libAtoms/libcleri",
              "d12f5faba985e0f4a04025f84c0e6c1a025a366b"),  # extxyz submodule pin (unchanged since v0.4.0)
    # pyleri (pure Python) is needed at build time to generate the grammar
    # parser sources; vendored as an sdist and used via PYTHONPATH since the
    # rootfs pip/site machinery is not usable in the build sandbox
    ArchiveSource("https://files.pythonhosted.org/packages/3a/0e/0e384ad4a9a603895f28da0fa32260402e372d26f3333a9ccd09de2bdf96/pyleri-1.5.0.tar.gz",
                  "0715a433e5b97e3d2fd8f74b4e57871e365eb3a1c7a09fb70d2f78700fd25e4c"),
]

# Bash recipe for building across all platforms.
# Upstream now builds with Meson, but its top-level meson.build is geared to
# producing Python wheels (it requires a Python installation and generates the
# grammar via pyleri at setup time). The standalone shared library target is
# just four C files, so they are compiled directly, mirroring what the old
# Makefile (used by the previous version of this recipe) did.
script = raw"""
cd $WORKSPACE/srcdir/extxyz

# place the vendored libcleri submodule
rm -rf libcleri
cp -r ../libcleri libcleri

# generate the key/value grammar parser sources (extxyz_kv_grammar.c/.h);
# python3 -S skips the rootfs site module, which fails to import
cd libextxyz
PYLERI_DIR=$(echo $WORKSPACE/srcdir/pyleri-*)
PYTHONPATH=$PYLERI_DIR python3 -S ../python/extxyz/extxyz_kv_grammar.py

# build the vendored libcleri statically
# (gnu99 rather than c99: libcleri uses POSIX strdup/strncasecmp)
cd ../libcleri
mkdir -p build
cd build
${CC} -O2 -fPIC -std=gnu99 -I../inc $(pcre2-config --cflags) -c ../src/*.c
ar rcs libcleri.a *.o

# link the shared library
cd ../../libextxyz
mkdir -p ${libdir} ${includedir}
${CC} -O2 -fPIC -std=gnu99 -shared -o ${libdir}/libextxyz.${dlext} \
    extxyz.c extxyz_kv_grammar.c fast_format.c extxyz_dispatch.c \
    -I../libcleri/inc $(pcre2-config --cflags) \
    ../libcleri/build/libcleri.a $(pcre2-config --libs8)
install -Dv extxyz.h ${includedir}/extxyz.h

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
