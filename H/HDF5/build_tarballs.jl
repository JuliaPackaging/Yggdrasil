using BinaryBuilder

# Collection of sources required to build HDF5
name = "HDF5"
version = v"1.10.5"

sources = [
    # Crib MacOS and Linux binaries from PyPI
    "https://files.pythonhosted.org/packages/98/06/0e711ae0c95d92ec238218448a15c23590cb117ded59e4bfa322b085b59e/h5py-2.9.0-cp27-cp27m-macosx_10_6_intel.macosx_10_9_intel.macosx_10_9_x86_64.macosx_10_10_intel.macosx_10_10_x86_64.whl" => "f3b49107fbfc77333fc2b1ef4d5de2abcd57e7ea3a1482455229494cf2da56ce",
    "https://files.pythonhosted.org/packages/11/6c/b23aa4269df44df11b0409372bc20c3d249a4c7f7554009166010b2cc296/h5py-2.9.0-cp27-cp27m-manylinux1_i686.whl" => "0f94de7a10562b991967a66bbe6dda9808e18088676834c0a4dcec3fdd3bcc6f",
    "https://files.pythonhosted.org/packages/c8/d6/a1f58a4ebb2cfe93dcbae2e8e8cee3d81aeda8851b5a56cdae9a4eae6a60/h5py-2.9.0-cp27-cp27m-manylinux1_x86_64.whl" => "713ac19307e11de4d9833af0c4bd6778bde0a3d967cafd2f0f347223711c1e31",

    # Take advantage of msys2 mingw builds of HDF5 for Windows
    "http://repo.msys2.org/mingw/i686/mingw-w64-i686-hdf5-1.10.5-1-any.pkg.tar.xz" => "d29a56297219e1981f393e266ee515605237323fc20b0a69a45961c4bfe5e9da",
    "http://repo.msys2.org/mingw/i686/mingw-w64-i686-szip-2.1.1-2-any.pkg.tar.xz" => "58b5efe1420a2bfd6e92cf94112d29b03ec588f54f4a995a1b26034076f0d369",
    "http://repo.msys2.org/mingw/i686/mingw-w64-i686-zlib-1.2.11-7-any.pkg.tar.xz" => "addf6c52134027407640f1cbdf4efc5b64430f3a286cb4e4c4f5dbb44ce55a42",
    "http://repo.msys2.org/mingw/x86_64/mingw-w64-x86_64-szip-2.1.1-2-any.pkg.tar.xz" => "ec8fe26370b0673c4b91f5ccf3404907dc7c24cb9d75c7b8830aa93a7c13ace7",
    "http://repo.msys2.org/mingw/x86_64/mingw-w64-x86_64-hdf5-1.10.5-1-any.pkg.tar.xz" => "e01196dd53711304aa4026932c153171606efc4d6938dd3c172b6b40d9e7cdd9",
    "http://repo.msys2.org/mingw/x86_64/mingw-w64-x86_64-zlib-1.2.11-7-any.pkg.tar.xz" => "1decf05b8ae6ab10ddc9035929014837c18dd76da825329023da835aec53cec2",

     # We need some special compiler support libraries from mingw
     "http://repo.msys2.org/mingw/i686/mingw-w64-i686-gcc-libs-9.1.0-3-any.pkg.tar.xz" => "416819d44528e856fb1f142b41fd3b201615d19ddaed8faa5d71296676d6fa17",

    # License file
    "https://support.hdfgroup.org/ftp/HDF5/releases/COPYING" => "1001425406c6f36ba30f7ac863c4b44a0355dfd5a0a0cf71e1f27201193a3f1e",
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/
mkdir -p ${prefix}/lib ${prefix}/bin

# If we're on Windows, extract from msys2 builds.  Otherwise, extract from .whl files
if [[ ${target} == x86_64-*mingw* ]]; then
    mv mingw64/bin/*.dll ${prefix}/bin
elif [[ ${target} == i686-*mingw* ]]; then
    mv mingw32/bin/*.dll ${prefix}/bin
else
    if [[ ${target} == x86_64-linux-gnu ]]; then
        WHL_FILE="*-h5py-*manylinux1_x86_64*.whl"
        LIBSDIR=.libs
    elif [[ ${target} == i686-linux-gnu ]]; then
        WHL_FILE="*-h5py-*manylinux1_i686*.whl"
        LIBSDIR=.libs
    elif [[ ${target} == x86_64-apple-darwin* ]]; then
        WHL_FILE="*-h5py-*macosx*.whl"
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

# Remove the hash from license file name and then install it
mv ${WORKSPACE}/srcdir/*-COPYING ${WORKSPACE}/srcdir/COPYING
install_license ${WORKSPACE}/srcdir/COPYING
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
products = [
    LibraryProduct("libhdf5", :libhdf5),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Zlib_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
