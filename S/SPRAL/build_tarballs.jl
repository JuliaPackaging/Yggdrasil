# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SPRAL"
version = v"2025.1.8"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ralna/spral.git", "c715ad652041cae79311321fba7f2ee1d0b3d478")
]

# Bash recipe for building across all platforms
script = raw"""
# Update Ninja
cp ${host_prefix}/bin/ninja /usr/bin/ninja

cd ${WORKSPACE}/srcdir/spral

if [[ "${target}" == *mingw* ]]; then
  HWLOC="hwloc-15"
  LBT="blastrampoline-5"
else
  HWLOC="hwloc"
  LBT="blastrampoline"
fi

meson setup builddir --cross-file=${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson \
                     --prefix=$prefix \
                     -Dlibhwloc=$HWLOC \
                     -Dlibblas=$LBT \
                     -Dliblapack=$LBT

meson compile -C builddir
meson install -C builddir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)
filter!(p -> arch(p) != "riscv64", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libspral", :libspral),
    ExecutableProduct("spral_ssids", :spral_ssids)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec(name="Ninja_jll", uuid="76642167-d241-5cee-8c94-7a494e8cb7b7")),
    Dependency(PackageSpec(name="METIS_jll", uuid="d00139f3-1899-568f-a2f0-47f597d42d70")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
    Dependency(PackageSpec(name="Hwloc_jll", uuid="e33a78d0-f292-5ffc-b300-72abe9b543c8")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9.1.0", julia_compat="1.9")
