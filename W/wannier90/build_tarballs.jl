# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "wannier90"
version = v"4.0.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/wannier-developers/wannier90.git",
              "971c8b64bfe703c747a52655e1d59936597fe8ea", tag="v$(version)"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wannier90/

# Upstream's CMake build needs CMake >= 3.25, hence the host CMake_jll
${host_bindir}/cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DWANNIER90_SHARED_LIBS=ON \
    -DWANNIER90_TEST=OFF \
    -DBLAS_LIBRARIES="${libdir}/libopenblas.${dlext}" \
    -DLAPACK_LIBRARIES="${libdir}/libopenblas.${dlext}"
${host_bindir}/cmake --build build --parallel ${nproc}
${host_bindir}/cmake --install build

# Upstream installs the executables with a `.x` suffix (on every OS); use the usual names
for exe in wannier90 postw90; do
    mv ${bindir}/${exe}.x ${bindir}/${exe}${exeext}
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libwannier90", :libwannier90),
    ExecutableProduct("wannier90", :wannier90),
    ExecutableProduct("postw90", :postw90),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec(; name="CMake_jll")),
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
