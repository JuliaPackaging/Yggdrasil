# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "UBPF"
version = v"0.0.1" # Temporary fake version, until ubpf provides releases

# Collection of sources required to complete build
sources = [
    # Use jpsamaroo's repo until upstream (iovisor/ubpf) becomes active
    GitSource("https://github.com/jpsamaroo/ubpf.git", "173a58790af1fdefc67aea6e22aaec0d6d8b4d67")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/ubpf/vm
if [[ "${target}" == *mingw* ]]; then
sed -i 's/-fPIC//g' Makefile
elif [[ "${target}" == *bsd* ]]; then
sed -i 's#endian.h#sys/endian.h#g' *.c *.h
fi
make -j $(nproc)
make PREFIX=${prefix} install
cd ..
install_license LICENSE-APACHE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(x->!(Sys.iswindows(x)||Sys.isapple(x)), supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libubpf", :libubpf)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
