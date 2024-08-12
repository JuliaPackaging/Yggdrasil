# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

name = "XRootD_cxxwrap"
version = v"0.1.0"

# Collection of sources required to build XRootD_julia
sources = [
    GitSource("https://github.com/peremato/XRootD_cxxwrap.git",
              "f924f95f0b3fc396ca496ea0f88f2ca15fcb92ee"),
]

# Bash recipe for building across all platforms
script = raw"""

cmake ${WORKSPACE}/srcdir/XRootD_cxxwrap -B build \
    -DJulia_PREFIX=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17

VERBOSE=ON cmake --build build --config Release --target install -- -j${nproc}

install_license XRootD_cxxwrap/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")

# platforms supported by libjulia
platforms = vcat(libjulia_platforms.(julia_versions)...)

# platforms supported by XRootD
platforms = filter(p -> libc(p) != "musl" && os(p) != "freebsd" && os(p) != "windows", platforms) |> expand_cxxstring_abis

# The products that we will ensure are always built
products = [
    LibraryProduct("libXRootDWrap", :libXRootDWrap),
    FileProduct("XRootD-export.jl", :XRootD_exports),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("libjulia_jll"),
    Dependency("libcxxwrap_julia_jll"; compat="0.11.2"),
    Dependency("XRootD_jll"; compat = "~5.6.9"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
               preferred_gcc_version=v"9", 
               julia_compat="1.6")

