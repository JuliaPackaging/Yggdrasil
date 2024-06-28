using BinaryBuilder, Pkg

name = "OpenModelica"
version = v"1.23.0"

sources = [
   GitSource("https://github.com/OpenModelica/OpenModelica",
              af881831d7c702a9afe1870d3b6e58cc57cdc926),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir -p "${libdir}"

cd OpenModelica
cmake -S . -B build_cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build build_cmake --parallel 10 --target install

install_license OSMC-license.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
]

# The products that we will ensure are always built
products = [
    BinaryProduct("omc", :omc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency(PackageSpec(name="libblastrampoline_jll"),
    BuildDependency("flex_jll"),
    BuildDependency("boost_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; lazy_artifacts=true, julia_compat="1.6")
