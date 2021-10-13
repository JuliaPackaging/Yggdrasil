# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SoapyPlutoSDR"
version = v"0.2.1" # not yet tagged

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pothosware/SoapyPlutoSDR.git", "ac9a9da5c14c73e752796618d56e259ca1ac6b11")
]

dependencies = [
    Dependency("libiio_jll"; compat="~0.23.0"),
    Dependency("soapysdr_jll"; compat="~0.8.0"),
    Dependency("libad9361_iio_jll"; compat="~0.2.0")    
]

# Bash recipe for building across all platforms
script = raw"""
cd SoapyPlutoSDR

mkdir build && cd build
if [[ "${target}" != *-apple-* ]]; then
    cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \
        ..
    make -j${nproc}
    make install
fi
if [[ "${target}" == *-apple-* ]]; then
    cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release \
        -DLibIIO_INCLUDE_DIR=${libdir}/iio.framework/Versions/0.23/Headers/ \
        -DLibIIO_LIBRARY=${libdir}/iio.framework/Versions/0.23/iio \
        -DLibAD9361_INCLUDE_DIR=${libdir}/ad9361.framework/Versions/0.2/Headers/ \
        -DLibAD9361_LIBRARY=${libdir}/ad9361.framework/Versions/0.2/ad9361 \
        ..
    make -j${nproc}
    make install
    mv ${libdir}/SoapySDR/modules0.8/libPlutoSDRSupport.so  ${libdir}/SoapySDR/modules0.8/libPlutoSDRSupport.dylib
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)
platforms = expand_cxxstring_abis(platforms) # requested by auditor

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libPlutoSDRSupport", :libPlutoSDRSupport, ["lib/SoapySDR/modules0.8/"])
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
