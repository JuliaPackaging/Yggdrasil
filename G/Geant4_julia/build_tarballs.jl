# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Geant4_julia"
version = v"0.1.0"

# reminder: change the above version if restricting the supported julia versions
julia_versions = [v"1.6.3", v"1.7", v"1.8", v"1.9", v"1.10"]
julia_compat = join("~" .* string.(getfield.(julia_versions, :major)) .* "." .* string.(getfield.(julia_versions, :minor)), ", ")

# Collection of sources required to build Geant4_julia
sources = [
    GitSource("https://github.com/peremato/Geant4_cxxwrap.git",
              "f109fc10ef6fcf1e5fecd972312c7a8016af5b0d"),
]

# Bash recipe for building across all platforms
script = raw"""

cmake ${WORKSPACE}/srcdir/Geant4_cxxwrap -B build \
    -DJulia_PREFIX=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17

VERBOSE=ON cmake --build build --config Release --target install -- -j${nproc}

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
platforms = filter(p -> libc(p) != "musl" && os(p) != "windows" && os(p) != "freebsd" && arch(p) != "armv6l", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libGeant4Wrap", :libGeant4Wrap),
    FileProduct("Geant4-export.jl", :Geant4_exports),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("libjulia_jll"),
    Dependency("libcxxwrap_julia_jll"),
    Dependency("Geant4_jll", v"11.1.1"),
    Dependency("Expat_jll"),
    Dependency("Xerces_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8", julia_compat=julia_compat)
          
