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

#CPP flags needed in configure statement to help *-musl-* builds configure scripts find sqlite3.h, unsure exactly why?

./configure \
    --prefix=${prefix} \
    --libdir=${libdir} \
    --includedir=${includedir} \
    --build=${MACHTYPE} \
    --host=${target} \
    --with-docs=no \
    CPPFLAGS="-I{includedir}"

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
    Dependency("ICU_jll"; compat="69.1")
    Dependency(PackageSpec(name="SQLite_jll", uuid="76ed43ae-9a5d-5a62-8c75-30186b810ce8"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;preferred_gcc_version=v"5", julia_compat="1.6")
