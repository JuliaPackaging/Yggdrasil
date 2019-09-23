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
cd $WORKSPACE/srcdir/Python-*/
./configure --prefix="${prefix}" --host="${target}" --build="${MACHTYPE}" \
    --disable-ipv6 \
    PYTHON_FOR_BUILD=python3 \
    ac_cv_file__dev_ptmx=yes \
    ac_cv_file__dev_ptc=no
make -j${nproc} CFLAGSFORSHARED="-Wno-error=implicit-function-declaration" _PYTHON_HOST_PLATFORM=${target}
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
