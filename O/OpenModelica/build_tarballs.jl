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
      -DBLAS_LIBRARIES="${libdir}/libblastrampoline.${dlext}" \
      -DOM_ENABLE_GUI_CLIENTS=OFF 
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
    Dependency("libblastrampoline_jll"; compat="5.8.0"),
    Dependency("Ipopt_jll"),
    Dependency("LibCURL_jll"),
    Dependency("util_linux_jll"),
    Dependency("OpenCL_jll"),
    BuildDependency("flex_jll"),
    BuildDependency("boost_jll"),
    BuildDependency("LLVMOpenMP_jll"),
    BuildDependency("OpenCL_Headers_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; lazy_artifacts=true, julia_compat="1.6")
