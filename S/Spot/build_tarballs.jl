# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "jlspot"
version = v"2.9.7"
julia_version = v"1.6.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://www.lrde.epita.fr/dload/spot/spot-2.9.7.tar.gz","1eea67e3446cdbbbb705ee6e26fd869020cdb7d82c563fead9cb4394b9baa04c"),
    GitSource("https://github.com/MaximeBouton/jlspot.git", "db47fb1b69b7c0e28690c0635fc9eb36c41debe3")
    ]
    
    # Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd spot-2.9.7/
# make sure pdf is older than .tex to not trigger latexmk during build 
# touch doc/tl/tl.tex
# touch doc/tl/tl.pdf
./configure --prefix=${prefix}/spot-build --build=${MACHTYPE} --host=${target} --disable-python
make -j${nproc} && make install

# build with cmake 
cd $WORKSPACE/srcdir/jlspot/spot-julia
# edit the CMAKE script to find libcxxwrap 
# "/home/maxime/cxxwrap-test/libcxxwrap-julia-build"

# edit the CMAKE script to find spot-build
sed -i 's#\${CMAKE_SOURCE_DIR}/../spot-build/#\${CMAKE_INSTALL_PREFIX}/spot-build/#g' CMakeLists.txt


# Override compiler ID to silence the horrible "No features found" cmake error
if [[ $target == *"apple-darwin"* ]]; then
  macos_extra_flags="-DCMAKE_CXX_COMPILER_ID=AppleClang -DCMAKE_CXX_COMPILER_VERSION=10.0.0 -DCMAKE_CXX_STANDARD_COMPUTED_DEFAULT=11"
fi
Julia_PREFIX=$prefix
mkdir build
cd build
cmake -DJulia_PREFIX=$Julia_PREFIX -DCMAKE_FIND_ROOT_PATH=$prefix -DJlCxx_DIR=$prefix/lib/cmake/JlCxx -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} $macos_extra_flags -DCMAKE_BUILD_TYPE=Release ../
VERBOSE=ON cmake --build . --config Release --target install -- -j${nproc}

install_license $WORKSPACE/srcdir/jlspot/LICENSE.md

exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc")
    # Platform("x86_64", "windows"),
    # Platform("x86_64", "macos")
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
    ExecutableProduct("genltl", :genltl, "spot-build/bin"),
    LibraryProduct("libspot", :libspot, "spot-build/lib"),
    ExecutableProduct("ltl2tgta", :ltl2tgta, "spot-build/bin"),
    ExecutableProduct("ltlsynt", :ltlsynt, "spot-build/bin"),
    ExecutableProduct("ltlcross", :ltlcross, "spot-build/bin"),
    LibraryProduct("libspotgen", :libspotgen, "spot-build/lib"),
    ExecutableProduct("autcross", :autcross, "spot-build/bin"),
    ExecutableProduct("genaut", :genaut, "spot-build/bin"),
    ExecutableProduct("ltl2tgba", :ltl2tgba, "spot-build/bin"),
    ExecutableProduct("randaut", :randaut, "spot-build/bin"),
    ExecutableProduct("autfilt", :autfilt, "spot-build/bin"),
    ExecutableProduct("ltlfilt", :ltlfilt, "spot-build/bin"),
    ExecutableProduct("ltlgrind", :ltlgrind, "spot-build/bin"),
    ExecutableProduct("ltldo", :ltldo, "spot-build/bin"),
    LibraryProduct("libbddx", :libbddx, "spot-build/lib"),
    LibraryProduct("libspotltsmin", :libspotltsmin, "spot-build/lib"),
    ExecutableProduct("randltl", :randltl, "spot-build/bin"),
    ExecutableProduct("dstar2tgba", :dstar2tgba, "spot-build/bin"),
    LibraryProduct("libspot_julia", :libspot_julia, "lib")
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libcxxwrap_julia_jll"),
    BuildDependency(PackageSpec(name="libjulia_jll", version=julia_version))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9")
