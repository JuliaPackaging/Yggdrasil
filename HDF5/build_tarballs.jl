using BinaryBuilder, Pkg

# Collection of sources required to build Nettle
name = "HDF5"
version = v"1.10.5"
sources = [
    # Crib MacOS and Linux binaries from PyPI
    "https://files.pythonhosted.org/packages/98/06/0e711ae0c95d92ec238218448a15c23590cb117ded59e4bfa322b085b59e/h5py-2.9.0-cp27-cp27m-macosx_10_6_intel.macosx_10_9_intel.macosx_10_9_x86_64.macosx_10_10_intel.macosx_10_10_x86_64.whl" => "f3b49107fbfc77333fc2b1ef4d5de2abcd57e7ea3a1482455229494cf2da56ce",
    "https://files.pythonhosted.org/packages/11/6c/b23aa4269df44df11b0409372bc20c3d249a4c7f7554009166010b2cc296/h5py-2.9.0-cp27-cp27m-manylinux1_i686.whl" => "0f94de7a10562b991967a66bbe6dda9808e18088676834c0a4dcec3fdd3bcc6f",
    "https://files.pythonhosted.org/packages/c8/d6/a1f58a4ebb2cfe93dcbae2e8e8cee3d81aeda8851b5a56cdae9a4eae6a60/h5py-2.9.0-cp27-cp27m-manylinux1_x86_64.whl" => "713ac19307e11de4d9833af0c4bd6778bde0a3d967cafd2f0f347223711c1e31",

    # Use musm's mingw builds
    "https://github.com/musm/hdf5-builds/files/3366273/hdf5-1.10.5-x86_64.zip" => "b4bf5067aa30210c13706c9dcfb1e99626c5139b1ae0a21102445ae0132791bc",
    "https://github.com/musm/hdf5-builds/files/3366272/hdf5-1.10.5-i686.zip" => "31acf68b75cf81a6ca00abbd820c85cdf2d610490b8bd7decd9ee29e7de9b791",

    # We need some special compiler support libraries from mingw
    "http://repo.msys2.org/mingw/i686/mingw-w64-i686-gcc-libs-9.1.0-3-any.pkg.tar.xz" => "416819d44528e856fb1f142b41fd3b201615d19ddaed8faa5d71296676d6fa17",
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
mkdir -p ${prefix}/lib ${prefix}/bin

# If we're on Windows, extract from msys2 builds.  Otherwise, extract from .whl files
if [[ ${target} == x86_64-*mingw* ]]; then
    mv hdf5-1.10.5-x86_64/hdf5-1.10.5_x86_64/bin/{libhdf5,zlib}*.dll ${prefix}/bin
    mv hdf5-1.10.5-x86_64/hdf5-1.10.5_x86_64/bin/*.exe ${prefix}/bin
elif [[ ${target} == i686-*mingw* ]]; then
    mv hdf5-1.10.5-i686/hdf5-1.10.5-i686/bin/{libhdf5,zlib}*.dll ${prefix}/bin
    mv hdf5-1.10.5-i686/hdf5-1.10.5-i686/bin/*.exe ${prefix}/bin

    # We need this special libgcc_s version as well
    mv mingw32/bin/libgcc_s_dw2*.dll ${prefix}/bin
else
    if [[ ${target} == x86_64-linux-gnu ]]; then
        WHL_FILE="h5py-*manylinux1_x86_64*.whl"
        LIBSDIR=.libs
    elif [[ ${target} == i686-linux-gnu ]]; then
        WHL_FILE="h5py-*manylinux1_i686*.whl"
        LIBSDIR=.libs
    elif [[ ${target} == x86_64-apple-darwin* ]]; then
        WHL_FILE="h5py-*macosx*.whl"
        LIBSDIR=.dylibs
    else
        echo "ERROR: Unsupported platform ${target}" >&2
        exit 1
    fi

    unzip "${WHL_FILE}"
    
    mv h5py/${LIBSDIR}/lib{sz,aec,hdf5}* ${prefix}/lib
fi

# We want libhdf5 to use OUR libz, so we force it to:
if [[ ${target} == *linux* ]]; then
    # We want libhdf5 to use OUR libz, so we force it to:
    for f in ${prefix}/lib/lib{sz,aec,hdf5}*; do
        patchelf --replace-needed $(basename h5py/${LIBSDIR}/libz*.${dlext}*) libz.${dlext}.1 ${f}
    done
elif [[ ${target} == *apple* ]]; then
    for f in ${prefix}/lib/lib{sz,aec,hdf5}*; do
        install_name_tool -change $(basename h5py/${LIBSDIR}/libz*.${dlext}*) libz.1.${dlext} ${f}
    done
fi
    

# We need to be able to access `libhdf5` directly, so symlink it from the hashed filename from manylinux pypi
if [[ ${target} == *linux* ]]; then
    libhdf5name=$(basename ${prefix}/lib/libhdf5-*.${dlext}*)
    base="${libhdf5name%%.*}"
    ext="${libhdf5name#$base}"
    ln -s ${libhdf5name} ${prefix}/lib/libhdf5${ext}
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64),
    Linux(:i686),
    MacOS(),
    Windows(:x86_64),
    Windows(:i686),
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, ["libhdf5"], :libhdf5),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.4/build_Zlib.v1.2.11.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

