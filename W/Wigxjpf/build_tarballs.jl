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

# Split platforms based on quadmath support
# libquadmath is available on x86/x86_64 Linux and Windows (MinGW)
# NOT available on macOS (Apple Clang doesn't provide it)
platforms = supported_platforms(; experimental = true)

# Platforms with quadmath support: x86/x86_64 on Linux and Windows
platforms_with_quadmath = filter(platforms) do p
    arch(p) in ["i686", "x86_64"] && (Sys.islinux(p) || Sys.iswindows(p))
end

# Platforms without quadmath support: all others
platforms_without_quadmath = filter(platforms) do p
    !(arch(p) in ["i686", "x86_64"] && (Sys.islinux(p) || Sys.iswindows(p)))
end

# Products for platforms WITH quadmath
products_with_quadmath = [
    LibraryProduct("libwigxjpf_shared", :libwigxjpf),
    LibraryProduct("libwigxjpf_quadmath_shared", :libwigxjpf_quadmath),
]

# Products for platforms WITHOUT quadmath
products_without_quadmath = [LibraryProduct("libwigxjpf_shared", :libwigxjpf)]

# Build for x86/x86_64 platforms (with quadmath support)
build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms_with_quadmath,
    products_with_quadmath,
    dependencies;
    julia_compat = "1.6",
)

# Build for other platforms (without quadmath)
build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms_without_quadmath,
    products_without_quadmath,
    dependencies;
    julia_compat = "1.6",
)
