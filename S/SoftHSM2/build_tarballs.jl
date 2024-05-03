# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SoftHSM2"
version = v"2.6.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/opendnssec/SoftHSMv2",
              "7f99bedae002f0dd04ceeb8d86d59fc4a68a69a0"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SoftHSMv2
cmake -B build \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DENABLE_STATIC=OFF \
      -DRUN_ECC=0 \
      -DRUN_GOST=0 \
      -DRUN_AES_KEY_WRAP=0 \
      -DRUN_AES_KEY_WRAP_PAD=0
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; exclude=Sys.iswindows))


# The products that we will ensure are always built
products = [
    LibraryProduct("libsofthsm2", :libsofthsm2, "lib/softhsm"),
    ExecutableProduct("softhsm2-keyconv", :softhsm2_keyconv),
    ExecutableProduct("softhsm2-util", :softhhsm2_util),
    ExecutableProduct("softhsm2-dump-file", :softhsm2_dump_file)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="3.0.8")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6")
