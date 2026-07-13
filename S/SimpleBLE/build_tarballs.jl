# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SimpleBLE"
version = v"0.12.1"

# Collection of sources required to complete build
# Using libsimplecble archives for Windows and macOS (contain both libs)
# Linux will be built from source
sources = [
    # Pre-built binaries for Windows (libsimplecble contains both DLLs)
    ArchiveSource("https://github.com/simpleble/simpleble/releases/download/v$(version)/libsimplecble_windows-x64.zip", "d6aa05c6a8f0ea710419dc82ea00c4ebbcd37a4d9644f70d79b94b6baf03c888"; unpack_target="windllx64"),
    ArchiveSource("https://github.com/simpleble/simpleble/releases/download/v$(version)/libsimplecble_windows-x86.zip", "1be89fda486cdcecfeda78b1c78ed1c3e502544f6d9fbbd4362b9844cfb435c2"; unpack_target="windllx32"),

    # Pre-built binaries for macOS (libsimplecble contains both .dylibs)
    ArchiveSource("https://github.com/simpleble/simpleble/releases/download/v$(version)/libsimplecble_macos-x64.zip", "c466ca02c70db1b78d731e635d4c15e4c125c9526fdebc7012ccc2660d1ba39b"; unpack_target="libsimplecble_macos_x64"),
    ArchiveSource("https://github.com/simpleble/simpleble/releases/download/v$(version)/libsimplecble_macos-aarch64.zip", "11d2a6a88fe02a79a0a6571d0df11c44801ca7c8b7be408b7245421b0a6f6308"; unpack_target="libsimplecble_macos_aarch64"),

    # Source code for building Linux and for license
    GitSource("https://github.com/simpleble/simpleble.git", "d1b7110644f0f9cb850d6ab43f7d461ca9d4031e"),

    # dbus source: built locally for Linux to satisfy CMake find_package
    # without pulling in Dbus_jll as a runtime dependency (which breaks
    # communication with the system bus daemon).
    ArchiveSource("https://dbus.freedesktop.org/releases/dbus/dbus-1.16.2.tar.xz",
                  "0ba2a1a4b16afe7bceb2c07e9ce99a8c2c3508e5dec290dbb643384bd6beb7e2"),
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
    # Build dbus from source locally so CMake finds it, but DON'T declare
    # Dbus_jll as a dependency — this prevents BinaryBuilder's audit from
    # adding "using Dbus_jll" to the generated JLL wrapper, which would
    # load Dbus_jll's bundled libdbus-1.so at runtime and break connection
    # to the system bus daemon.
    cd $WORKSPACE/srcdir/dbus-*
    meson setup builddbus \
        --buildtype=release \
        --cross-file=${MESON_TARGET_TOOLCHAIN} \
        --prefix=${prefix} \
        -Ddbus_user=messagebus \
        -Dsystem_pid_file=/var/run/dbus.pid \
        -Dverbose_mode=false \
        -Dinotify=auto \
        -Dasserts=false \
        -Duser_session=true \
        -Dsession_socket_dir=/tmp \
        -Dx11_autolaunch=disabled \
        -Dmodular_tests=disabled \
        -Dc_link_args=-lrt
    meson compile -C builddbus
    meson install -C builddbus

    cd $WORKSPACE/srcdir/simpleble/
    cmake -S simplecble -B build_simplecble \
        -DCMAKE_INSTALL_PREFIX=$prefix \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=TRUE
    cmake --build build_simplecble --parallel ${nproc}
    cd build_simplecble/
    make install

    # Remove local dbus build artifacts from prefix, but keep the shared
    # library itself (libdbus-1.so*) so the audit's dlopen succeeds.
    # The library will be bundled in the tarball and found via RPATH $ORIGIN
    # at runtime, without needing Dbus_jll as a dependency.
    rm -rf ${prefix}/bin/dbus-* ${prefix}/etc/dbus-1 \
           ${prefix}/include/dbus-1.0 ${prefix}/lib/cmake/DBus1 \
           ${prefix}/lib/dbus-1.0 \
           ${prefix}/lib/pkgconfig/dbus-1.pc ${prefix}/libexec/dbus-* \
           ${prefix}/share/dbus-1 ${prefix}/share/doc/dbus \
           ${prefix}/share/xml/dbus-1
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
# NOTE: dbus-1 is built from source on Linux (see script above) instead of
# using Dbus_jll, because BinaryBuilder's audit would otherwise add Dbus_jll
# as a runtime dependency (via NEEDED libdbus-1.so.3), loading its bundled
# libdbus-1.so which cannot connect to the system bus daemon.
# Expat_jll is needed at build time for the dbus library (XML config parsing).
dependencies = [
    BuildDependency(PackageSpec(name="Expat_jll", uuid="2e619515-83b5-522b-bb60-26c02a35a201"); platforms=filter(p -> Sys.islinux(p) && libc(p) == "glibc", platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
# Using GCC 11 for Linux (available for both Linux and MinGW, though we use pre-built for Windows)
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"11")
