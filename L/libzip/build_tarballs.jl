# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libzip"
version = v"1.11.1"

# Collection of sources required to complete build
sources = [
    # The official download from libzip.org fails with a certificate problem
    ArchiveSource("https://github.com/nih-at/libzip/releases/download/v$(version)/libzip-$(version).tar.gz",
                  "c0e6fa52a62ba11efd30262290dc6970947aef32e0cc294ee50e9005ceac092a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libzip-*
cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nprocs}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libzip", :libzip),
    ExecutableProduct("zipcmp", :zipcmp),
    ExecutableProduct("zipmerge", :zipmerge),
    ExecutableProduct("ziptool", :ziptool),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Bzip2_jll", uuid="6e34b625-4abd-537c-b88f-471c36dfa7a0"); compat="1.0.8"),
    Dependency(PackageSpec(name="GnuTLS_jll", uuid="0951126a-58fd-58f1-b5b3-b08c7c4a876d");
               platforms=filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)),
    Dependency(PackageSpec(name="XZ_jll", uuid="ffd25f8a-64ca-5728-b0f7-c24cf3aae800")),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
    Dependency(PackageSpec(name="Zstd_jll", uuid="3161d3a3-bdf6-5164-811a-617609db77b4")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6")
