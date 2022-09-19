# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
import Pkg: PackageSpec

# reminder: change the above version if restricting the supported julia versions
julia_versions = [v"1.6.3", v"1.7.0", v"1.8.0", v"1.9.0"]
julia_compat = join("~" .* string.(getfield.(julia_versions, :major)) .* "." .* string.(getfield.(julia_versions, :minor)), ", ")

name = "libcgal_julia"
rversion = v"0.18.0"
version = VersionNumber(rversion.major,
                        rversion.minor,
                        100rversion.patch)

isyggdrasil = get(ENV, "YGGDRASIL", "") == "true"
rname = "libcgal-julia"

# Collection of sources required to build CGAL
sources = [
    isyggdrasil ?
        GitSource("https://github.com/rgcv/$rname.git",
                  "dab124dce4a0818d2fff672d12c45bb783454f31") :
        DirectorySource(joinpath(ENV["HOME"], "src/github/rgcv/$rname"))
]

# Bash recipe for building across all platforms
jlcgaldir = ifelse(isyggdrasil, rname, ".")
script = raw"""
## pre-build setup
# exit on error
set -eu

macosflags=
case $target in
  *apple-darwin*)
    macosflags="-DCMAKE_CXX_COMPILER_ID=AppleClang"
    macosflags="$macosflags -DCMAKE_CXX_COMPILER_VERSION=10.0.0"
    macosflags="$macosflags -DCMAKE_CXX_STANDARD_COMPUTED_DEFAULT=11"
    ;;
esac
""" * """
## configure build
cmake $jlcgaldir """ * raw"""\
  -B /tmp/build \
  `# cmake specific` \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_FIND_ROOT_PATH=$prefix \
  -DCMAKE_INSTALL_PREFIX=$prefix \
  -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN \
  `# tell jlcxx where julia is` \
  -DJulia_PREFIX=$prefix \
  $macosflags

## and away we go..
VERBOSE=ON cmake --build /tmp/build --config Release --target install -- -j$nproc
""" * """
install_license $jlcgaldir/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = reduce(vcat, libjulia_platforms.(julia_versions))
# generates an abundance of linker errors and notes about using older versions
# of GCC.  Among many things, this could be related to boost as well.  However,
# requiring newer versions would, much like libsingular_julia, require the
# dropping of older julia versions <1.6.  CGAL also contains several deprecation
# notices when configured against newer versions of boost, so it's probably best
# to avoid it for now as well.
filter!(p -> arch(p) ≠ "armv7l", platforms)
# filter experimental platforms
filter!(p -> arch(p) ≠ "armv6l", platforms)
filter!(p -> !(Sys.isapple(p) && arch(p) == "aarch64"), platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcgal_julia_exact", :libcgal_julia_exact),
    LibraryProduct("libcgal_julia_inexact", :libcgal_julia_inexact),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="libjulia_jll")),
    BuildDependency(PackageSpec(name="GMP_jll", version=v"6.2.0")),
    BuildDependency(PackageSpec(name="MPFR_jll", version=v"4.1.1")),

    Dependency("CGAL_jll", compat="~5.5"),
    Dependency("libcxxwrap_julia_jll", compat="0.9.2"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"8",
    julia_compat)
