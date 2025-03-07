# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "aws_lc"
version = v"1.48.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/awslabs/aws-lc.git", "d0356099f6b668697cdb381dfb09f9a694a6c9c2"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/aws-lc

# Patch for finding definition of AT_HWCAP2 for PowerPC
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/ppc64le_auxvec.patch"

if [[ "${target}" == arm-linux-* ]]; then
   # They force using `-Werror` _and_ they have warnings:
   # <https://github.com/aws/aws-lc/issues/1185>.
   sed -i 's/-Werror//g' CMakeLists.txt
fi

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
	-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
	-DBUILD_TESTING=OFF \
	-DCMAKE_BUILD_TYPE=Release \
        -DDISABLE_GO=ON \
        -DBUILD_SHARED_LIBS=OFF \
	-GNinja \
	..
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Disable 32-bit because it's too much for the time being
platforms = expand_cxxstring_abis(supported_platforms(; exclude=p->Sys.iswindows(p) || Sys.isapple(p)))

# The products that we will ensure are always built
products = [
    FileProduct("lib/libcrypto.a", :libcrypto),
    FileProduct("lib/libssl.a", :libssl),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    # # TODO: this is needed only for Windows, but it looks like filtering
    # # platforms for `HostBuildDependency` is broken
    # HostBuildDependency("NASM_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")
