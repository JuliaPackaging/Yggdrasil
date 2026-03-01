using BinaryBuilder, Pkg

name = "GIAC"
version = v"2.0.0"

# Collection of sources required to build GIAC
sources = [
  ArchiveSource("https://www-fourier.univ-grenoble-alpes.fr/~parisse/giac/giac-$(version).tar.gz",
                "6abfab95bae0981201498ce0dd6086da65ab0ff45f96ef6dd7d766518f6741f4"
  ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/giac*

update_configure_scripts
autoreconf -vif

./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --disable-rpath \
    --enable-shared \
    --disable-fltk \
    --disable-micropy

make -j${nproc}
make install
"""

# Build for all supported platforms
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libgiac", :libgiac),
    LibraryProduct("libxcas", :libxcas),
    ExecutableProduct("icas", :icas),
    ExecutableProduct("xcas", :xcas),
    FileProduct("share/giac/aide_cas", :aide_cas),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Gettext_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("GettextRuntime_jll"),
    Dependency("GMP_jll"),
    Dependency("MPFR_jll"),
    Dependency("OpenBLAS32_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Use GCC 7+ for C++17 support
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"7", julia_compat="1.6")
