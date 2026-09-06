using BinaryBuilder, Pkg

name = "fplll"
version = v"5.5.0"

sources = [
    ArchiveSource("https://github.com/fplll/fplll/releases/download/$(version)/fplll-$(version).tar.gz",
                  "f0af6bdd0ebd5871e87ff3ef7737cb5360b1e38181a4e5a8c1236f3476fec3b2"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/fplll*

# We need either GMP or MPIR
options=(
    --prefix=${prefix}
    --build=${MACHTYPE}
    --host=${target}
    --enable-static=no
    --with-gmp=${prefix}
    --with-mpfr=${prefix}
    # --with-mpir=${prefix}
    --with-qd=${prefix}
)

./configure ${options[@]}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# Windows is not supported
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libfplll", :libfplll),
    ExecutableProduct("fplll", :fplll),
    ExecutableProduct("latticegen", :latticegen),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("GMP_jll"; compat="6.2.1"),
    Dependency("MPFR_jll"; compat="4.2.0"),
    # Dependency("MPIR_jll"; compat="3.0.2"),
    Dependency("QD_jll"; compat="2.3.24"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"5")
