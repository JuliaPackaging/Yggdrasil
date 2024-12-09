# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "nativefiledialog_extended"
version = v"1.1.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/btzy/nativefiledialog-extended.git", "5786fabceeaee4d892f3c7a16b243796244cdddc")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/nativefiledialog-extended
# NATIVE   mingw, apple
# PORTAL   linux ~armv6l
# GTK3     linux ~armv6l, freebsd
# PORTAL?  linux  armv6l

function build_nfd()
{
    BUILD=${1}
    PREFIX=${2}
    NFD_PORTAL=${3}
    NFD_APPEND_EXTENSION=${4}
    cmake -B ${BUILD} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_STANDARD=11 \
        -DCMAKE_C_FLAGS="-Wall -Wextra -pedantic" \
        -DCMAKE_CXX_FLAGS="-Wall -Wextra -pedantic" \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_INSTALL_PREFIX=${PREFIX} \
        -DNFD_PORTAL=${NFD_PORTAL} \
        -DNFD_APPEND_EXTENSION=${NFD_APPEND_EXTENSION} \
        .
    cmake --build ${BUILD} --parallel ${nproc}
    cmake --install ${BUILD}
}

# NATIVE and PORTAL
BUILD="build"
PREFIX="${prefix}"
NFD_PORTAL=OFF
NFD_APPEND_EXTENSION=OFF
if [[ "${target}" == *linux* || "${target}" == *freebsd* ]] ; then
    NFD_PORTAL=ON
fi
if [[ "${target}" != *armv6l* ]] ; then
    build_nfd ${BUILD} ${PREFIX} ${NFD_PORTAL} ${NFD_APPEND_EXTENSION}
fi

# GTK3
BUILD="build_gtk"
if [[ "${target}" == *linux* ]] ; then
    PREFIX="${prefix}/gtk"
    mkdir ${PREFIX}
fi
NFD_PORTAL=OFF
NFD_APPEND_EXTENSION=ON
if [[ "${target}" != *armv6l* && "${target}" != *x86_64-*-musl* ]] ; then
    build_nfd ${BUILD} ${PREFIX} ${NFD_PORTAL} ${NFD_APPEND_EXTENSION}
    if [[ "${target}" == *mingw32* ]] ; then
        install ${PREFIX}/bin/libnfd.${dlext} ${libdir}/libnfd_gtk.${dlext}
    else
        install ${PREFIX}/lib/libnfd.${dlext} ${libdir}/libnfd_gtk.${dlext}
    fi
    rm -r ${PREFIX}
else
    ln -s ${prefix}/lib/libnfd.${dlext} ${libdir}/libnfd_gtk.${dlext}
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms())

dbus_gtk = filter(p->Sys.islinux(p)||Sys.isfreebsd(p), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libnfd", :libnfd)
    LibraryProduct("libnfd_gtk", :libnfd_gtk)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="Xorg_xorgproto_jll", uuid="c4d99508-4286-5418-9131-c86396af500b"); platforms=platforms)
    BuildDependency(PackageSpec(name="GTK3_jll", uuid="77ec8976-b24b-556a-a1bf-49a033a670a6"); platforms=platforms)
    Dependency(PackageSpec(name="Dbus_jll", uuid="ee1fde0b-3d02-5ea6-8484-8dfef6360eab"); platforms=dbus_gtk)
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")
