# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Collection of sources required to build GMPBuilder
name = "GMP"
version = v"6.1.2"
sources = [
    "https://gmplib.org/download/gmp/gmp-6.1.2.tar.bz2" =>
    "5275bb04f4863a13516b2f39392ac5e272f5e1bb8057b18aec1c9b79d73d8fb2",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gmp-*

# Update config.status
update_configure_scripts

# Patch `configure` to include `$LDFLAGS` in its tests.  This is necessary on FreeBSD.
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/configure.patch

# Include Julia-carried patches
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/gmp_alloc_overflow_func.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/gmp-exception.patch

flags=(--enable-cxx --enable-shared --disable-static)

# On x86_64 architectures, build fat binary
if [[ ${proc_family} == intel ]]; then
    flags+=(--enable-fat)
fi

./configure --prefix=$prefix --build=${MACHTYPE} --host=${target} ${flags[@]}

# Something is broken in the libtool that gets generated on macOS; I can't
# figure out why, but `hardcode_action` is set to blank for CXX files.  /shrug
sed -i -e 's&hardcode_action=$&hardcode_action=immediate&g' libtool

make -j${nproc}
make install

# On Windows, we need to make sure that the non-versioned dll names exist too
if [[ ${target} == *mingw* ]]; then
    cp -v ${prefix}/bin/libgmp-*.dll ${prefix}/bin/libgmp.dll
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libgmp", :libgmp)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
