using BinaryBuilder
using Pkg

# See https://github.com/JuliaPackaging/Yggdrasil/blob/master/C/CGAL/build_tarballs.jl

name = "gismo"
version = v"24.08.0"
sources = [
    GitSource("https://github.com/gismo/gismo.git",       # The URL of the git repository
              "da35b0cf10137902cc2f6fe1979c8e27b42f944a") # The commit hash to checkout
]

# NOTE: to control nproc, use the environment variable BINARYBUILDER_NPROC=<number of processors>
script = raw"""
cmake -B build                                      \
  `# cmake specific`                                \
  -DCMAKE_INSTALL_PREFIX=${prefix}                  \
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}  \
  -DCMAKE_BUILD_TYPE=Release                        \
  -DGISMO_OPTIONAL="gsCInterface"                   \
  -DGISMO_gsCInterface_HEAD=""                      \
  -DGISMO_WITH_OPENMP=ON                            \
  -DTARGET_ARCHITECTURE=none                        \
  -DCMAKE_CXX_STANDARD=11                           \
  -DNOFORTRAN=ON                                    \
  gismo/

cmake --build build --target install -- -j$nproc gismo

install_license ${WORKSPACE}/srcdir/gismo/LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# platforms = [AnyPlatform()]
platforms = expand_cxxstring_abis(supported_platforms())

products = [
    LibraryProduct("libgismo", :libgismo),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms))
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9")
