using BinaryBuilder, Pkg

name = "OpenModelica"
version = v"1.23.0"

sources = [
   GitSource("https://github.com/OpenModelica/OpenModelica",
             "af881831d7c702a9afe1870d3b6e58cc57cdc926"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir -p "${libdir}"

apk add openjdk17

cd OpenModelica
cmake -S . -B build_cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBLAS_LIBRARIES="${libdir}/libopenblas.${dlext}" \
      -DOM_ENABLE_GUI_CLIENTS=OFF 

cat /workspace/srcdir/OpenModelica/build_cmake/CMakeFiles/CMakeError.log

cmake --build build_cmake --parallel 10 --target install

install_license OSMC-license.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("omc", :omc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenBLAS32_jll"),
    Dependency("Ipopt_jll"),
    Dependency("LibCURL_jll"),
    Dependency("util_linux_jll"),
    Dependency("boost_jll"),
    Dependency("flex_jll"),
    Dependency("LLVMOpenMP_jll"),
    Dependency("OpenCL_jll"),
    BuildDependency("OpenCL_Headers_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
               julia_compat="1.6",
               preferred_gcc_version=v"9")
