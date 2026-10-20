# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Wigxjpf"
version_string = "1.13"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    ArchiveSource(
        "http://fy.chalmers.se/subatom/wigxjpf/wigxjpf-$version_string.tar.gz",
        "90ab9bfd495978ad1fdcbb436e274d6f4586184ae290b99920e5c978d64b3e6a",
    ),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wigxjpf-*

find /usr/share/cmake -name "._*" -delete 2>/dev/null

# Fix and enhance CMakeLists.txt
atomic_patch -p1 ../patches/cmake_build.patch

# Build with CMake
cmake -S . -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_LIBDIR=${libdir} \
    -DCMAKE_INSTALL_BINDIR=${bindir}

cmake --build build
cmake --install build

# On platforms without quadmath (non-x86 or macOS), build a stub library
# that provides error messages instead of undefined symbols
if [ ! -f "${libdir}/libwigxjpf_quadmath_shared.so" ] && [ ! -f "${libdir}/libwigxjpf_quadmath_shared.dylib" ]; then
    echo "Building stub quadmath library for platform without quadmath support..."

    # Compile stub
    ${CC} -fPIC -O2 -Wno-unused-parameter -c ../quadmath_stub.c -o quadmath_stub.o

    # Link stub with base library to create a self-contained quadmath stub
    if [ "$(uname)" = "Darwin" ]; then
        ${CC} -dynamiclib quadmath_stub.o -L"${libdir}" -lwigxjpf_shared \
              -o "${libdir}/libwigxjpf_quadmath_shared.dylib"
    else
        ${CC} -shared quadmath_stub.o -L"${libdir}" -lwigxjpf_shared \
              -o "${libdir}/libwigxjpf_quadmath_shared.so"
    fi
fi

install_license COPYING COPYING.LESSER
"""

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(
        PackageSpec(
            name = "CompilerSupportLibraries_jll",
            uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae",
        ),
    ),
]

# All platforms get both products
# On x86/x86_64 Linux/Windows: real quadmath library
# On others: symlink for compatibility
platforms = supported_platforms(; experimental = true)

products = [
    LibraryProduct("libwigxjpf_shared", :libwigxjpf),
    LibraryProduct("libwigxjpf_quadmath_shared", :libwigxjpf_quadmath),
]

# Single build call for all platforms
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
)
