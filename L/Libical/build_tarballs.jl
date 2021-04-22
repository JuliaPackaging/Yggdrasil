# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Libical"
version = v"3.0.9"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/libical/libical/releases/download/v$(version)/libical-$(version).tar.gz",
                  "bd26d98b7fcb2eb0cd5461747bbb02024ebe38e293ca53a7dfdcb2505265a728"),
]

# Bash recipe for building across all platforms
script = raw"""
cd libical-*

apk add glib-dev libxml2-dev

# Don't try this at home, it's bad
ln -s /opt/${host_target}/${host_target}/sys-root/usr/lib/libc.so /usr/lib/libc.so

FLAGS=(
    -DCMAKE_BUILD_TYPE=Release
    -DSHARED_ONLY=true
    -DICAL_BUILD_DOCS=false
    -DGOBJECT_INTROSPECTION=false
    -DLIBICAL_BUILD_TESTING=false
    -DWITH_CXX_BINDINGS=false
    -DCMAKE_FIND_USE_CMAKE_SYSTEM_PATH="FALSE"
)

# cross compiling libical requires a binary from the native build
(
    mkdir native_build && cd native_build
    # It would be nice to have `HOST_PKG_CONFIG_*` variables.
    export PKG_CONFIG_SYSROOT_DIR="/usr"
    export PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/lib64/pkgconfig:/usr/share/pkgconfig"
    export LDFLAGS="-L/usr/lib"
    cmake -DCMAKE_INSTALL_PREFIX=../native_prefix \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN} \
        "${FLAGS[@]}" \
        ..
    make -j${nproc}
    make install
)

# Hint to find libstc++, required to link against C++ libs when using C compiler
if [[ "${target}" == *-linux-* ]]; then
    if [[ "${nbits}" == 32 ]]; then
        export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib"
    else
        export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib64"
    fi
fi

export LDFLAGS="-L${libdir}"
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    "${FLAGS[@]}" \
    -DIMPORT_ICAL_GLIB_SRC_GENERATOR="../native_prefix/lib64/cmake/LibIcal/IcalGlibSrcGenerator.cmake" \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    # TBD
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Glib_jll"),
    Dependency("XML2_jll"),
    Dependency("ICU_jll"),
    Dependency("Libffi_jll"),
    HostBuildDependency("ICU_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7")
