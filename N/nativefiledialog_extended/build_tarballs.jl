# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "nativefiledialog_extended"
version = v"1.2.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/btzy/nativefiledialog-extended.git", "86d5f2005fe1c00747348a12070fec493ea2407e")
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
build_nfd ${BUILD} ${PREFIX} ${NFD_PORTAL} ${NFD_APPEND_EXTENSION}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libnfd", :libnfd)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Dbus_jll", uuid="ee1fde0b-3d02-5ea6-8484-8dfef6360eab"); platforms=platforms)
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.10", preferred_gcc_version = v"5.2.0")
