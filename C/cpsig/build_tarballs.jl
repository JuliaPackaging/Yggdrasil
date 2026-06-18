using BinaryBuilder

name = "cpsig"
version = v"3.1.0"

sources = [
    GitSource(
        "https://github.com/daniil-shmelev/pySigLib.git",
        "377c712121cee078ec08bdf01cc6b76cc6f7fbd0";
        unpack_target = "pysiglib",
    ),
]

script = raw"""
cd ${WORKSPACE}/srcdir/pysiglib/pySigLib

# Replace upstream Python/JAX/CUDA-oriented root CMake with a minimal one.
# We only build siglib/cpsig, which provides the C ABI library libcpsig.
cat > CMakeLists.txt <<'EOF'
cmake_minimum_required(VERSION 3.16)
project(cpsig_jll LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

include(GNUInstallDirs)
find_package(Threads REQUIRED)

# Portable JLL: avoid -march=native / host CPU feature probing.
set(_enable_vec OFF CACHE BOOL "Disable cpsig vectorisation for portable JLL" FORCE)

# Do not use upstream install path; install into the JLL prefix ourselves.
set(CPSIG_SKIP_INSTALL ON CACHE BOOL "Skip upstream cpsig install rule" FORCE)

add_subdirectory(siglib/cpsig)

install(TARGETS cpsig
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

install(FILES
    siglib/cpsig/cpsig.h
    siglib/cpsig/cppch.h
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)
EOF

cmake -B build -S . \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_LIBDIR=lib

cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE
"""

platforms = supported_platforms()

products = [
    LibraryProduct(["libcpsig", "cpsig"], :libcpsig, ["lib", "bin"]),
    FileProduct("include/cpsig.h", :cpsig_h),
    FileProduct("include/cppch.h", :cppch_h),
]

dependencies = [
    HostBuildDependency("CMake_jll"),
]

build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    julia_compat = "1.6",
    preferred_gcc_version = v"10",
)
