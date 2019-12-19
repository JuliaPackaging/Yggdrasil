# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Python"
version = v"3.8.1"

# Collection of sources required to build Python
sources = [
    "https://www.python.org/ftp/python/$(version)/$(name)-$(version).tar.xz" =>
    "75894117f6db7051c1b34f37410168844bbb357c139a8a10a352e9bf8be594e8",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
# Having a global `python3` screws things up a bit, so get rid of that
rm -f $(which python3)

# We need these for the host python build
apk add zlib-dev libffi-dev

# Create fake `arch` command:
echo '#!/bin/bash' >> /usr/bin/arch
echo 'echo i386'   >> /usr/bin/arch
chmod +x /usr/bin/arch

# Patch out cross compile limitations
cd ${WORKSPACE}/srcdir/Python-*/
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cross_compile_configure_ac.patch
autoreconf -i

# Next, build host version
mkdir build_host && cd build_host

# Override `bb_target`, `CC`, etc... to give this `./configure` the impression
# that we are actually targeting `${MACHTYPE}` and not `${target}`
bb_target=${MACHTYPE} CC=${HOSTCC} CPPFLAGS=-I/usr/include LDFLAGS="-L/lib -L/usr/lib" ../configure --host="${MACHTYPE}" --build="${MACHTYPE}"
make -j${nproc} python sharedmods

# Next, build target version
cd ${WORKSPACE}/srcdir/Python-*/
mkdir build_target && cd build_target
export CPPFLAGS="${CPPFLAGS} -I${prefix}/include"
export LDFLAGS="${LDFLAGS} -L${prefix}/lib -L${prefix}/lib64"
export PATH=$(echo ${WORKSPACE}/srcdir/Python-*/build_host):$PATH
../configure --prefix="${prefix}" --host="${target}" --build="${MACHTYPE}" \
    --enable-shared \
    --disable-ipv6 \
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

# Disable windows for now, until we can sort through all of these patches
# and choose the ones that we need:
# https://github.com/msys2/MINGW-packages/tree/1e753359d9b55a46d9868c3e4a31ad674bf43596/mingw-w64-python3
platforms = filter(p -> !isa(p, Windows), platforms)

# The products that we will ensure are always built
products = Product[
    ExecutableProduct(:python, ["python", "python3"]),
    LibraryProduct(:libpython, ["libPython3"]),
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
