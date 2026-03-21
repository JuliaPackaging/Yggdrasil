# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SoapyRemote"
version = v"0.5.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pothosware/SoapyRemote.git", "f920d9bf10f62f67c8e31b7dc25090bc784e5210")
]

dependencies = [
    Dependency("soapysdr_jll", v"0.8.1"; compat="0.8")
]

# Bash recipe for building across all platforms
script = raw"""
cd SoapyRemote
install_license LICENSE_1_0.txt

mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      ..
make -j${nproc}
make install
if [[ "${target}" == *-apple-* ]]; then
    mv ${libdir}/SoapySDR/modules0.8/libremoteSupport.so  ${libdir}/SoapySDR/modules0.8/libremoteSupport.dylib
fi
"""

# TODO: build against libavahi-client for auto-discovery.
#       avahi is tricky to build, with lots of dependencies,
#       including libdaemon which we haven't wrapped yet.

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; exclude=Sys.iswindows))
# TODO: Windows is supposedly supported, but doesn't compile.

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libremoteSupport", :libremoteSupport, ["lib/SoapySDR/modules0.8/"])
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
