# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "rocm_smi_lib"
version = v"4.2.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/RadeonOpenCompute/rocm_smi_lib/archive/refs/tags/rocm-$(version).tar.gz", "c31bf91c492f00d0c5ab21e45afbd7baa990e4a8d7ce9b01e3b988e5fdd53f50")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/rocm_smi_lib-rocm-*/
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_PREFIX_PATH=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("liboam", :liboam, "oam/lib"),
    LibraryProduct("librocm_smi64", :librocm_smi, "rocm_smi/lib"),
    FileProduct("rocm_smi/bindings/rsmiBindings.py", :rsmiBindingspy),
    FileProduct("bin/rsmiBindings.py", :rsmiBindingspylink),
    FileProduct("bin/rocm_smi.py", :rocm_smipy)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8.1.0")
