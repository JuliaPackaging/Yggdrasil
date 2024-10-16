# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "argp_standalone"
version = v"1.4.1"

# Collection of sources required to build argp-standalone
sources = [
    GitSource("https://github.com/ericonr/argp-standalone.git", "743004c68e7358fb9cd4737450f2d9a34076aadf"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/argp-standalone

for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

autoreconf -i
CFLAGS="-fPIC" ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}

cat >LICENSE <<EOF
The contents of this repository https://github.com/ericonr/argp-standalone is based on GNU C Library source code
and changes from Niels Möller (https://www.lysator.liu.se/~nisse/) and collaborators.
It is licensed primarily under the GNU Lesser General Public License, version 2.1 or later (SPDX: LGPL-2.1-or-later).
EOF

install -Dvm 644 argp.h -t $prefix/include
install -Dvm 644 libargp.a -t $prefix/lib

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    # argp is meant as a build-time dependency to be included in other recipes, so static library only
    FileProduct("lib/libargp.a", :libargp),
    FileProduct("include/argp.h", :argp_h),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
   julia_compat="1.6",preferred_gcc_version=v"6")
