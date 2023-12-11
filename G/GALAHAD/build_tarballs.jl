# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GALAHAD"
version = v"4.1.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ralna/GALAHAD.git", "33214d72ac384e77682dc2a947a9d99bdca87009")
]

# Bash recipe for building across all platforms
script = raw"""
# Update Ninja
cp ${host_prefix}/bin/ninja /usr/bin/ninja

cd ${WORKSPACE}/srcdir/GALAHAD

if [[ "${target}" == *mingw* ]]; then
  LBT="blastrampoline-5"
else
  LBT="blastrampoline"
fi

meson setup builddir --cross-file=${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson \
                     --prefix=$prefix -Dlibblas=$LBT -Dliblapack=$LBT

meson compile -C builddir
meson install -C builddir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libgalahad_single", :libgalahad_single),
    LibraryProduct("libgalahad_double", :libgalahad_double)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec(name="Ninja_jll", uuid="76642167-d241-5cee-8c94-7a494e8cb7b7")),
    Dependency(PackageSpec(name="METIS_jll", uuid="d00139f3-1899-568f-a2f0-47f597d42d70")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
    Dependency(PackageSpec(name="Hwloc_jll", uuid="e33a78d0-f292-5ffc-b300-72abe9b543c8")),
    Dependency(PackageSpec(name="MUMPS_seq_jll", uuid="d7ed1dd3-d0ae-5e8e-bfb4-87a502085b8d")),
    # Dependency(PackageSpec(name="PaStiX_jll", uuid="46e5285b-ff06-5712-adf2-cc145d39f096")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0", julia_compat="1.9")
