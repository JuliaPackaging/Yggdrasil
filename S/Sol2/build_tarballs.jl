# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Sol2"
version = v"3.3.1"

sources = [
    GitSource("https://github.com/ThePhD/sol2.git",
        "dca62a0f02bb45f3de296de3ce00b1275eb34c25"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/sol2

for p in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 "${p}"
done

# Lua 5.5 compatibility for the compat headers. These files ship with CRLF
# line endings, so keep the replacements line-ending agnostic.
sed -i 's/LUA_VERSION_NUM > 504/LUA_VERSION_NUM > 505/g' \
    include/sol/compatibility/compat-5.3.h
sed -i 's/LUA_VERSION_NUM == 504/LUA_VERSION_NUM >= 504/g' \
    include/sol/compatibility/compat-5.4.h

# Sol2 is header-only: mark its CMake version file ARCH_INDEPENDENT so the AnyPlatform
# package is not rejected by find_package() on targets with a different pointer size.
sed -i 's/COMPATIBILITY AnyNewerVersion)/COMPATIBILITY AnyNewerVersion ARCH_INDEPENDENT)/' CMakeLists.txt

cmake -B build \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build

# Make the AnyPlatform config-version arch-independent (else 32-bit consumers reject the 64-bit-built config).
sed -i 's/"8" STREQUAL ""/"" STREQUAL ""/' ${prefix}/lib/cmake/sol2/sol2-config-version.cmake

install_license LICENSE.txt
"""

platforms = [AnyPlatform()]

products = [
    FileProduct("include/sol/sol.hpp", :sol_hpp),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version=v"7")
