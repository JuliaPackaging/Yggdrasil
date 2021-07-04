# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libsharp2"
 # ↓ This version number is a lie to be able to build for experimental
 # ↓ platforms, but it shouldn't be a problem as the library is abandoned.
version = v"1.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.mpcdf.mpg.de/mtr/libsharp.git", "54856313a5fcfb6a33817b7dfa28c4b1965ffbd1"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libsharp/
sed -i 's/LT_INIT.*/LT_INIT\(\[win32-dll\]\)/g' configure.ac
sed -i 's/libsharp2_la_LDFLAGS = -version-info 0:0:0/libsharp2_la_LDFLAGS = -version-info 0:0:0 -no-undefined/g' Makefile.am
autoreconf -i
if [[ "${target}" == x86_64-* ]] && [[ "${target}" != *-apple-* ]]; then
    # Enable runtime multiarch, but not for macOS, see
    # https://gitlab.mpcdf.mpg.de/mtr/libsharp/-/blob/6374a3a1ffb935443c56f09b371b11cf982a7e28/COMPILE
    export CFLAGS="-DMULTIARCH"
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsharp2", :libsharp2)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               # GCC 7 needed to enable multiarch.
               preferred_gcc_version=v"7", julia_compat="1.6")
