# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

julia_versions = [v"1.6.3", v"1.7", v"1.8", v"1.9", v"1.10"]
name = "MParT"
version = v"2.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/MeasureTransport/MParT.git",
    "aa08ee2e2ff765282b14351f07a81ea0c963783a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir MParT/build && cd MParT/build

if [[ "${target}" == *-freebsd* ]]; then
    export LDFLAGS="-lexecinfo"
fi

cmake -DCMAKE_INSTALL_PREFIX=$prefix \
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
  -DCMAKE_CXX_FLAGS="-I${includedir}/eigen3 -fopenmp" \
  -DCMAKE_BUILD_TYPE=Release \
  -DMPART_BUILD_TESTS=OFF \
  -DMPART_PYTHON=OFF \
  -DMPART_MATLAB=OFF \
  -DMPART_JULIA=ON \
  -DJulia_PREFIX=${prefix} \
  ..

make -j${nprocs} install
"""
include("../../L/libjulia/common.jl")

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(vcat(libjulia_platforms.(julia_versions)...))
platforms = filter!(p -> !Sys.iswindows(p) && nbits(p) == 64, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmpart", :libmpart),
    LibraryProduct("libmpartjl", :libmpartjl, String["julia"]),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libcxxwrap_julia_jll"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="Kokkos_jll", uuid="c1216c3d-6bb3-5a2b-bbbf-529b35eba709"); compat="=3.7.2"),
    BuildDependency(PackageSpec(name="Eigen_jll", uuid="bc6bbf8a-a594-5541-9c57-10b0d0312c70")),
    BuildDependency("libjulia_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9")

