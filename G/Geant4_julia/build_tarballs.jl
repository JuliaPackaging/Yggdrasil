# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

name = "Geant4_julia"
version = v"0.2.3"

# Collection of sources required to build Geant4_julia
sources = [
    GitSource("https://github.com/peremato/Geant4_cxxwrap.git",
              "f011260477bb13463b0bf87eac78bedb447dd3e6"),
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

install_license Geant4_cxxwrap/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")

# Filter Julia versions:
# - 1.13 is not supported by libcxxwrap_julia_jll v0.13 (to be changed in the future!)
# - Remove versions below current LTS (1.10)
filter!(x -> x < v"1.13" && x >= v"1.10", julia_versions)

# platforms supported by libjulia
platforms = vcat(libjulia_platforms.(julia_versions)...)

# platforms supported by Geant4
platforms = filter(p -> libc(p) != "musl" && 
                        os(p) != "freebsd" && 
                        arch(p) != "armv6l" && 
                        arch(p) != "armv7l" && 
                        arch(p) != "i686" &&
                        arch(p) != "riscv64", platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libGeant4Wrap", :libGeant4Wrap),
    FileProduct("Geant4-export.jl", :Geant4_exports),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("libjulia_jll"),
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("libcxxwrap_julia_jll"; compat="0.13.2"),
    Dependency("Geant4_jll"; compat="11.3.2")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
               preferred_gcc_version=v"9", 
               julia_compat="1.6")
