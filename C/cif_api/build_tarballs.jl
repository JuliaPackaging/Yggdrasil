# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cif_api"
version = v"0.4.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/COMCIFS/cif_api/archive/refs/tags/v0.4.2.tar.gz", "803fa1d0525bb51407754fa63b9439ba350178f45372103e84773ed4871b3924")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cif_api-*

update_configure_scripts

if [[ "${target}" == *-linux-* ]]; then
# Hint to find libstdc++, required to link against C++ libs when using C compiler
    if [[ "${nbits}" == 32 ]]; then
        export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib"
    else
        export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib64"
    fi
fi

./configure \
--prefix=${prefix} \
--libdir=${libdir} \
--includedir=${includedir} \
--build=${MACHTYPE} \
--host=${target} \
--with-docs=no \
CPPFLAGS="-I/workspace/destdir/include"

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libcif", :libcif)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="ICU_jll", uuid="a51ab1cf-af8e-5615-a023-bc2c838bba6b"))
    Dependency(PackageSpec(name="SQLite_jll", uuid="76ed43ae-9a5d-5a62-8c75-30186b810ce8"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
