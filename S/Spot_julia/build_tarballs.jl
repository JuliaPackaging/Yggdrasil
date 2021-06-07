# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Spot_julia"
version = v"2.9.7"
julia_version = v"1.6.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://www.lrde.epita.fr/dload/spot/spot-2.9.7.tar.gz","1eea67e3446cdbbbb705ee6e26fd869020cdb7d82c563fead9cb4394b9baa04c"),
    GitSource("https://github.com/MaximeBouton/spot_julia.git", "9b59bebb96a973ba078f482128e3aeac1fe3cc38")
    ]
    
    # Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/spot-2.9.7/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-python
make -j${nproc}
make install

# build with cmake 
cd $WORKSPACE/srcdir/spot_julia/spot_julia

if [[ $target == *"mingw"* ]]; then
  cp -L ${prefix}/bin/*.dll ${prefix}/lib/
  rm ${prefix}/bin/*.dll
fi

# Override compiler ID to silence the horrible "No features found" cmake error
if [[ $target == *"apple-darwin"* ]]; then
  macos_extra_flags="-DCMAKE_CXX_COMPILER_ID=AppleClang -DCMAKE_CXX_COMPILER_VERSION=10.0.0 -DCMAKE_CXX_STANDARD_COMPUTED_DEFAULT=11"
fi
Julia_PREFIX=$prefix
mkdir build
cd build
cmake -DJulia_PREFIX=$Julia_PREFIX \
    -DCMAKE_SPOT_DIR=${prefix} \
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
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("x86_64", "windows"),
    Platform("x86_64", "macos")
]
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
    ExecutableProduct("genltl", :genltl, "bin"),
    LibraryProduct("libspot", :libspot, "lib"),
    ExecutableProduct("ltl2tgta", :ltl2tgta, "bin"),
    ExecutableProduct("ltlsynt", :ltlsynt, "bin"),
    ExecutableProduct("ltlcross", :ltlcross, "bin"),
    LibraryProduct("libspotgen", :libspotgen, "lib"),
    ExecutableProduct("autcross", :autcross, "bin"),
    ExecutableProduct("genaut", :genaut, "bin"),
    ExecutableProduct("ltl2tgba", :ltl2tgba, "bin"),
    ExecutableProduct("randaut", :randaut, "bin"),
    ExecutableProduct("autfilt", :autfilt, "bin"),
    ExecutableProduct("ltlfilt", :ltlfilt, "bin"),
    ExecutableProduct("ltlgrind", :ltlgrind, "bin"),
    ExecutableProduct("ltldo", :ltldo, "bin"),
    LibraryProduct("libbddx", :libbddx, "lib"),
    LibraryProduct("libspotltsmin", :libspotltsmin, "lib"),
    ExecutableProduct("randltl", :randltl, "bin"),
    ExecutableProduct("dstar2tgba", :dstar2tgba, "bin"),
    LibraryProduct("libspot_julia", :libspot_julia, "lib")
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libcxxwrap_julia_jll"),
    BuildDependency(PackageSpec(name="libjulia_jll", version=julia_version))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9")
