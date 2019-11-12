# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Python"
version = v"3.7.4"

# Collection of sources required to build Python
sources = [
    "https://www.python.org/ftp/python/$(version)/$(name)-$(version).tar.xz" =>
    "fb799134b868199930b75f26678f18932214042639cd52b16da7fd134cd9b13f",
]

# Bash recipe for building across all platforms
script = raw"""
# Having a global `python3` screws things up a bit, so get rid of that
rm -f $(which python3)

# We need these for the host python build
apk add zlib-dev libffi-dev

# First, build host version
cd $WORKSPACE/srcdir/Python-*/
mkdir build_host && cd build_host
CC=${HOSTCC} CPPFLAGS=-I/usr/include LDFLAGS="-L/lib -L/usr/lib" ../configure --host="${MACHTYPE}" --build="${MACHTYPE}"
make -j${nproc} python sharedmods

# Next, build target version
cd $WORKSPACE/srcdir/Python-*/
mkdir build_target && cd build_target
export CPPFLAGS="${CPPFLAGS} -I${prefix}/include"
export LDFLAGS="${LDFLAGS} -L${prefix}/lib -L${prefix}/lib64"
export PATH=$(echo ${WORKSPACE}/srcdir/Python-*/build_host):$PATH
../configure --prefix="${prefix}" --host="${target}" --build="${MACHTYPE}" \
    --enable-ipv6 \
    --with-ensurepip=no \
    ac_cv_file__dev_ptmx=no \
    ac_cv_file__dev_ptc=no \
    ac_cv_have_chflags=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Expat_jll",
    "Bzip2_jll",
    "Libffi_jll",
    "Zlib_jll",
    "XZ_jll"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
