# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SimpleBLE"
version = v"0.12.1"

# Collection of sources required to complete build
# Using libsimplecble archives for Windows (contain both DLLs) and macOS (contain both dylibs)
# Linux will be built from source; Dbus_jll provides headers/libs at build time via BuildDependency
sources = [
    # Pre-built binaries for Windows (libsimplecble contains both DLLs)
    ArchiveSource("https://github.com/simpleble/simpleble/releases/download/v$(version)/libsimplecble_windows-x64.zip", "d6aa05c6a8f0ea710419dc82ea00c4ebbcd37a4d9644f70d79b94b6baf03c888"; unpack_target="windllx64"),
    ArchiveSource("https://github.com/simpleble/simpleble/releases/download/v$(version)/libsimplecble_windows-x86.zip", "1be89fda486cdcecfeda78b1c78ed1c3e502544f6d9fbbd4362b9844cfb435c2"; unpack_target="windllx32"),

    # Pre-built binaries for macOS (libsimplecble contains both .dylibs)
    ArchiveSource("https://github.com/simpleble/simpleble/releases/download/v$(version)/libsimplecble_macos-x64.zip", "c466ca02c70db1b78d731e635d4c15e4c125c9526fdebc7012ccc2660d1ba39b"; unpack_target="libsimplecble_macos_x64"),
    ArchiveSource("https://github.com/simpleble/simpleble/releases/download/v$(version)/libsimplecble_macos-aarch64.zip", "11d2a6a88fe02a79a0a6571d0df11c44801ca7c8b7be408b7245421b0a6f6308"; unpack_target="libsimplecble_macos_aarch64"),

    # Source code for building Linux and for license
    GitSource("https://github.com/simpleble/simpleble.git", "d1b7110644f0f9cb850d6ab43f7d461ca9d4031e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
install_license simpleble/LICENSE.md

# Windows: use pre-built binaries (MinGW lacks WinRT headers)
if [[ ${target} == *mingw* ]]; then
    if [[ ${target} == i686* ]]; then
        cd windllx32/shared/bin/
    else
        cd windllx64/shared/bin/
    fi
    mkdir -p ${prefix}/bin
    cp -a simpleble.dll simplecble.dll ${prefix}/bin/
# Linux: build from source with GCC 11
elif [[ ${target} == *linux* ]]; then
    # Dbus_jll is available in the prefix as a BuildDependency, providing
    # headers and libdbus-1.so for CMake's find_package(DBus1).  We DON'T
    # declare Dbus_jll as a runtime dependency (BuildDependency only), so
    # the generated JLL wrapper has no "using Dbus_jll".  We remove all
    # dbus files from ${prefix} so they are not bundled in the tarball.
    # At runtime the system's libdbus-1.so.3 is resolved by ld.so.

    cd $WORKSPACE/srcdir/simpleble/
    cmake -S simplecble -B build_simplecble \
        -DCMAKE_INSTALL_PREFIX=$prefix \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=TRUE
    cmake --build build_simplecble --parallel ${nproc}
    cd build_simplecble/
    make install

    # Remove all dbus files from the prefix so they are not bundled.
    # The system's libdbus-1.so.3 will be resolved at runtime by ld.so.
    rm -rf ${prefix}/bin/dbus-* ${prefix}/etc/dbus-1 \
           ${prefix}/include/dbus-1.0 ${prefix}/lib/cmake/DBus1 \
           ${prefix}/lib/dbus-1.0 \
           ${prefix}/lib/pkgconfig/dbus-1.pc ${prefix}/libexec/dbus-* \
           ${prefix}/share/dbus-1 ${prefix}/share/doc/dbus \
           ${prefix}/share/xml/dbus-1 \
           ${prefix}/lib/libdbus-1*
# macOS: use pre-built binaries
elif [[ ${target} == *apple* ]]; then
    if [[ ${target} == x86_64* ]]; then
        cd libsimplecble_macos_x64/shared/lib/
    elif [[ ${target} == aarch64* ]]; then
        cd libsimplecble_macos_aarch64/shared/lib/
    else
        echo "Unsupported macOS architecture: ${target}"
        exit 1
    fi
    mkdir -p ${prefix}/lib
    cp -a libsimpleble*.dylib* libsimplecble*.dylib* ${prefix}/lib/
else
    echo "Unsupported target: ${target}"
    exit 1
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# Filter to only platforms that have pre-built binaries available or can be built from source
# Linux: x86_64, i686, aarch64, armv6l (glibc only)
# Windows: x86_64, i686
# macOS: x86_64, aarch64 (pre-built only)
filter!(p -> (Sys.islinux(p) && libc(p) == "glibc" && arch(p) in ("x86_64", "i686", "aarch64", "armv6l")) ||
              Sys.iswindows(p) ||
              (Sys.isapple(p) && arch(p) in ("x86_64", "aarch64")), platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
# Windows uses simpleble.dll/simplecble.dll, Linux uses libsimpleble.so/libsimplecble.so, macOS uses libsimpleble.dylib/libsimplecble.dylib
products = [
    LibraryProduct(["libsimplecble", "simplecble"], :simplecble),
    LibraryProduct(["libsimpleble", "simpleble"], :simpleble)
]

# Dependencies that must be installed before this package can be built
# NOTE: Dbus_jll is used as a BuildDependency to provide headers and
# libdbus-1.so for CMake's find_package(DBus1) at build time.  It is NOT
# a runtime Dependency, so the generated JLL has no "using Dbus_jll".
# After the build, all dbus files are removed from ${prefix} so they are
# not bundled.  At runtime the system's libdbus-1.so.3 is resolved by ld.so.
dependencies = [
    BuildDependency(PackageSpec(name="Dbus_jll", uuid="ee1fde0b-3d02-5ea6-8484-8dfef6360eab"); platforms=filter(p -> Sys.islinux(p), platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
# Using GCC 11 for Linux (available for both Linux and MinGW, though we use pre-built for Windows)
# dont_dlopen=true: skip the product-satisfaction dlopen check because
# libsimpleble.so NEEDS libdbus-1.so.3 which we remove from the prefix
# to avoid bundling (the system's libdbus is used at runtime).
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"11", dont_dlopen = true)
