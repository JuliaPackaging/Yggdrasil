# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SIFDecode"
version = v"2.6.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ralna/SIFDecode.git", "a94d9a0b00f3e215da27943f7c19809ca160166b")
]

# Bash recipe for building across all platforms
script = raw"""
# Update Ninja
cp ${host_prefix}/bin/ninja /usr/bin/ninja

cd ${WORKSPACE}/srcdir/SIFDecode
meson setup builddir --cross-file=${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson --prefix=$prefix -Ddefault_library=shared
meson compile -C builddir
meson install -C builddir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)
platforms = filter(p -> libgfortran_version(p) != v"3", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsifdecode", :libsifdecode),
    ExecutableProduct("sifdecoder_standalone", :sifdecoder_standalone),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec(name="Ninja_jll", uuid="76642167-d241-5cee-8c94-7a494e8cb7b7")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
