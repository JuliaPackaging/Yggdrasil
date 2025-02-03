# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Minuit2_Julia_Wrapper"
version = v"0.2"

sources = [
	GitSource("https://github.com/JuliaHEP/Minuit2_Julia_Wrapper.git",
              "de92f78ab964cc251d207b59f3b0e82e9b8892a0")
]

# Bash recipe for building across all platforms
script = raw"""

cmake ${WORKSPACE}/srcdir/Minuit2_Julia_Wrapper -B build \
    -DJulia_PREFIX=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17

VERBOSE=ON cmake --build build --config Release --target install -- -j${nproc}

install_license Minuit2_Julia_Wrapper/LICENSE 
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")

# platforms supported by libjulia
platforms = vcat(libjulia_platforms.(julia_versions)...)

# platforms supported by Minuit2
platforms = filter(p -> libc(p) != "musl" && 
                        os(p) != "freebsd" && 
                        arch(p) != "armv6l" && 
                        arch(p) != "armv7l" && 
                        arch(p) != "i686" &&
                        arch(p) != "riscv64", platforms) |> expand_cxxstring_abis

# The products that we will ensure are always built
products = [
    LibraryProduct("libMinuit2Wrap", :libMinuit2Wrap),
    FileProduct("Minuit2-export.jl", :Minuit2_exports),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("libjulia_jll"),
    Dependency("libcxxwrap_julia_jll"; compat="0.13.2"),
    Dependency("Minuit2_jll"; compat = "~6.34",)
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
    preferred_gcc_version=v"9", 
    julia_compat = "1.6")
