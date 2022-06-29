# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cif_api"
version = v"0.4.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/COMCIFS/cif_api/archive/refs/tags/v0.4.2.tar.gz", "803fa1d0525bb51407754fa63b9439ba350178f45372103e84773ed4871b3924"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cif_api-*

update_configure_scripts

if [[ ${target} == *mingw* ]]; then
    #remove win32 if branch to prevent file not found errors on make install?
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-remove-install-hook.patch
    autoreconf -vi
fi

#CPP flags needed to help *-musl-* builds configure scripts find sqlite3.h, unsure exactly why?
export CPPFLAGS="-I${includedir}"

./configure \
    --prefix=${prefix} \
    --libdir=${libdir} \
    --includedir=${includedir} \
    --build=${MACHTYPE} \
    --host=${target} \
    --with-docs=no \

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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;preferred_gcc_version=v"7", julia_compat="1.6")
