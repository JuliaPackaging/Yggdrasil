# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "fmusim"
version = v"0.0.39"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/modelica/Reference-FMUs.git",
              "c8d4e6d90fa14be49d7622badf30e38eebea5e0a"),
    # fmusim compiles three minizip sources (ioapi.c, unzip.c, iowin32.c)
    # directly from a zlib source tree, so we ship one alongside.
    GitSource("https://github.com/madler/zlib.git",
              "51b7f2abdade71cd9bb0e7a373ef2610ec6f9daf"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/Reference-FMUs*/
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/use-shared-deps.patch

case "${target}" in
    aarch64-*) FMI_ARCH=aarch64 ;;
    x86_64-*)  FMI_ARCH=x86_64  ;;
    *) echo "Unsupported target ${target}"; exit 1 ;;
esac

mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DWITH_FMUSIM=ON \
    -DFMI_VERSION=3 \
    -DFMI_ARCHITECTURE=${FMI_ARCH} \
    -DFMUSIM_VERSION="\"0.0.39\"" \
    -DZLIB_SRC_DIR=${WORKSPACE}/srcdir/zlib \
    ..

cmake --build . --target fmusim --parallel ${nproc}

install -Dm755 fmusim/fmusim${exeext} ${bindir}/fmusim${exeext}
install_license ../LICENSE.txt
"""

# Upstream supports only x86_64 / aarch64 on linux/macos/windows.
platforms = filter(supported_platforms()) do p
    os(p) in ("linux", "macos", "windows") &&
        arch(p) in ("x86_64", "aarch64") &&
        libc(p) != "musl"
end

# The products that we will ensure are always built
products = [
    ExecutableProduct("fmusim", :fmusim),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("XML2_jll"),
    Dependency("Zlib_jll"),
    Dependency("SUNDIALS_jll"; compat="~7"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
