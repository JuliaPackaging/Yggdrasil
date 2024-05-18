# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Spot_julia"
version = v"2.9.7"
julia_versions = [v"1.6.3", v"1.7", v"1.8", v"1.9", v"1.10"]

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://www.lrde.epita.fr/dload/spot/spot-2.9.7.tar.gz","1eea67e3446cdbbbb705ee6e26fd869020cdb7d82c563fead9cb4394b9baa04c"),
    GitSource("https://github.com/MaximeBouton/spot_julia.git", "6ffcf4b64f64fc9e3363db22f4cc57a957d28128")
    ]
    
# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/spot-2.9.7/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-python
make -j${nproc}
make install

# build with cmake 
cd $WORKSPACE/srcdir/spot_julia/spot_julia

# Override compiler ID to silence the horrible "No features found" cmake error
if [[ $target == *"apple-darwin"* ]]; then
  macos_extra_flags="-DCMAKE_CXX_COMPILER_ID=AppleClang -DCMAKE_CXX_COMPILER_VERSION=10.0.0 -DCMAKE_CXX_STANDARD_COMPUTED_DEFAULT=11"
fi
Julia_PREFIX=$prefix
mkdir build
cd build
cmake -DJulia_PREFIX=$Julia_PREFIX \
    -DCMAKE_SPOT_LIB_DIR=${libdir} \
    -DCMAKE_SPOT_INCLUDE_DIR=${includedir} \
    -DCMAKE_FIND_ROOT_PATH=$prefix \
    -DJlCxx_DIR=${libdir}/cmake/JlCxx \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    ${macos_extra_flags} \
    ${windows_extra_flags} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}
install_license $WORKSPACE/srcdir/spot_julia/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# # uncomment when pushing to yggdrasil
# # These are the platforms we will build for by default, unless further
# # platforms are passed in on the command line
# include("../../L/libjulia/common.jl")
# platforms = libjulia_platforms(julia_version)
# platforms = filter!(!Sys.iswindows, platforms) # Singular does not support Windows
# platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    ExecutableProduct("genltl", :genltl),
    LibraryProduct("libspot", :libspot),
    ExecutableProduct("ltl2tgta", :ltl2tgta),
    ExecutableProduct("ltlsynt", :ltlsynt),
    ExecutableProduct("ltlcross", :ltlcross),
    LibraryProduct("libspotgen", :libspotgen),
    ExecutableProduct("autcross", :autcross),
    ExecutableProduct("genaut", :genaut),
    ExecutableProduct("ltl2tgba", :ltl2tgba),
    ExecutableProduct("randaut", :randaut),
    ExecutableProduct("autfilt", :autfilt),
    ExecutableProduct("ltlfilt", :ltlfilt),
    ExecutableProduct("ltlgrind", :ltlgrind),
    ExecutableProduct("ltldo", :ltldo),
    LibraryProduct("libbddx", :libbddx),
    LibraryProduct("libspotltsmin", :libspotltsmin),
    ExecutableProduct("randltl", :randltl),
    ExecutableProduct("dstar2tgba", :dstar2tgba),
    LibraryProduct("libspot_julia", :libspot_julia)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(;name="libjulia_jll", version=v"1.10.9")),
    Dependency("libcxxwrap_julia_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9")
