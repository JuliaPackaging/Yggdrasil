# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

# needed for libjulia_platforms and julia_versions
include("../../L/libjulia/common.jl")

name = "libntl_julia"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

# Create CMakeLists.txt
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(libntl_julia_wrapper CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(JlCxx REQUIRED)

# Find NTL
find_path(NTL_INCLUDE_DIR NAMES NTL/ZZ.h PATHS ${prefix}/include)
find_library(NTL_LIBRARY NAMES ntl PATHS ${prefix}/lib)

add_library(libntl_julia SHARED libntl_julia.cpp)

target_link_libraries(libntl_julia
    PRIVATE JlCxx::cxxwrap_julia
    PRIVATE ${NTL_LIBRARY}
)

target_include_directories(libntl_julia
    PRIVATE ${NTL_INCLUDE_DIR}
)

target_compile_definitions(libntl_julia PRIVATE NTL_EXCEPTIONS=on)

set_target_properties(libntl_julia PROPERTIES
    PREFIX ""
    OUTPUT_NAME "libntl_julia"
)

install(TARGETS libntl_julia
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)
EOF

mkdir -p build && cd build

cmake .. \
    -DJulia_PREFIX=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=${prefix}

cmake --build . --parallel ${nproc}
cmake --install .
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line. We need CxxWrap support.
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libntl_julia", :libntl_julia),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(; name="libjulia_jll", version=v"1.10.0")),
    Dependency("libcxxwrap_julia_jll"; compat="~0.13, ~0.14"),
    Dependency("ntl_jll"; compat="~10.5"),
    Dependency("GMP_jll"; compat="6"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"10",
    julia_compat=libjulia_julia_compat(julia_versions))
