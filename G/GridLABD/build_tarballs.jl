# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GridLABD"
version = v"5.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/gridlab-d/gridlab-d.git", "1b2e463d3c149e999a2c5f04213477f545e01dc6"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gridlab-d/

git submodule update --init

atomic_patch     ../patches/apple-soname.patch
atomic_patch -p0 ../patches/gldcore-platform-unistd.patch
atomic_patch -p0 ../patches/gldcore-exec-wait.patch

mkdir cmake-build && cd cmake-build

if [[ ${target} == *apple* ]]; then
    cmake -S ${WORKSPACE}/srcdir/gridlab-d -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_BUILD_TYPE=Release -DCMAKE_SYSTEM_NAME=Darwin
else
    cmake -S ${WORKSPACE}/srcdir/gridlab-d -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_BUILD_TYPE=Release
fi

cmake --build . -j${nproc} --target install

install_license ${WORKSPACE}/srcdir/gridlab-d/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# platforms = [
#     # Platform("i686", "Linux"; libc="glibc"),
#     # Platform("x86_64", "Linux"; libc="glibc"),
#     # Platform("aarch64", "Linux"; libc="glibc"),
#     # Platform("armv6l", "Linux"; call_abi="eabihf", libc="glibc"),
#     # Platform("armv7l", "Linux"; call_abi="eabihf", libc="glibc"),
#     # Platform("powerpc64le", "Linux"; libc="glibc"),
#     # Platform("riscv64", "Linux"; libc="glibc"),
#     Platform("i686", "Linux"; libc="musl"),
#     Platform("x86_64", "Linux"; libc="musl"),
#     Platform("aarch64", "Linux"; libc="musl"),
#     Platform("armv6l", "Linux"; call_abi="eabihf", libc="musl"),
#     Platform("armv7l", "Linux"; call_abi="eabihf", libc="musl"),
#     Platform("x86_64", "macOS"),
#     # Platform("aarch64", "macOS"),
#     # Platform("x86_64", "FreeBSD"),
#     # Platform("aarch64", "FreeBSD"),
#     Platform("i686", "Windows"),
#     Platform("x86_64", "Windows"),
# ]

# The products that we will ensure are always built
products = [
    ExecutableProduct("gridlabd", :gridlabd)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9.1.0")
