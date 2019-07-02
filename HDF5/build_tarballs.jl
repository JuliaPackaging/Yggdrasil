using BinaryBuilder, Pkg

# Collection of sources required to build Nettle
name = "HDF5"
version = v"1.10.5"
sources = [
    "https://files.pythonhosted.org/packages/98/06/0e711ae0c95d92ec238218448a15c23590cb117ded59e4bfa322b085b59e/h5py-2.9.0-cp27-cp27m-macosx_10_6_intel.macosx_10_9_intel.macosx_10_9_x86_64.macosx_10_10_intel.macosx_10_10_x86_64.whl" => "f3b49107fbfc77333fc2b1ef4d5de2abcd57e7ea3a1482455229494cf2da56ce",
    "https://files.pythonhosted.org/packages/11/6c/b23aa4269df44df11b0409372bc20c3d249a4c7f7554009166010b2cc296/h5py-2.9.0-cp27-cp27m-manylinux1_i686.whl" => "0f94de7a10562b991967a66bbe6dda9808e18088676834c0a4dcec3fdd3bcc6f",
    "https://files.pythonhosted.org/packages/c8/d6/a1f58a4ebb2cfe93dcbae2e8e8cee3d81aeda8851b5a56cdae9a4eae6a60/h5py-2.9.0-cp27-cp27m-manylinux1_x86_64.whl" => "713ac19307e11de4d9833af0c4bd6778bde0a3d967cafd2f0f347223711c1e31",
    "https://files.pythonhosted.org/packages/e5/92/53f505d8aa76165c3aca74422632c5ad38d7ca2586078a453c6dfef18d38/h5py-2.9.0-cp27-cp27m-win32.whl" => "4162953714a9212d373ac953c10e3329f1e830d3c7473f2a2e4f25dd6241eef0",
    "https://files.pythonhosted.org/packages/59/9a/7b5b3c3f4b485630c32369739f20b5d1e674033ab5d2b9e1882de41d84bd/h5py-2.9.0-cp27-cp27m-win_amd64.whl" => "407b5f911a83daa285bbf1ef78a9909ee5957f257d3524b8606be37e8643c5f0",
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/

LIBSDIR=.libs
if [[ ${target} == x86_64-linux-gnu ]]; then
    WHL_FILE="h5py-2.9.0-cp27-cp27m-manylinux1_x86_64.whl"
elif [[ ${target} == i686-linux-gnu ]]; then
    WHL_FILE="h5py-2.9.0-cp27-cp27m-manylinux1_i686.whl"
elif [[ ${target} == x86_64-apple-darwin* ]]; then
    WHL_FILE="h5py-2.9.0-cp27-cp27m-macosx_10_6_intel.macosx_10_9_intel.macosx_10_9_x86_64.macosx_10_10_intel.macosx_10_10_x86_64.whl"
    LIBSDIR=.dylibs
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    WHL_FILE="h5py-2.9.0-cp27-cp27m-win_amd64.whl"
elif [[ ${target} == i686-w64-mingw32 ]]; then
    WHL_FILE="h5py-2.9.0-cp27-cp27m-win32.whl"
else
    echo "ERROR: Unsupported platform ${target}" >&2
fi


unzip "${WHL_FILE}"
mkdir -p ${prefix}/lib ${prefix}/bin

# Windows why do you hate everyone else
if [[ ${target} == *mingw* ]]; then
    mv h5py/hdf5.dll ${prefix}/bin
    mv h5py/hdf5_hl.dll ${prefix}/bin
else
    mv h5py/${LIBSDIR}/lib{sz,aec,hdf5}* ${prefix}/lib

    # We need to be able to access `libhdf5` directly, so just symlink it.
    if [[ ${target} != x86_64-apple-darwin* ]]; then
        libhdf5name=$(basename ${prefix}/lib/libhdf5-*.${dlext}*)
        base=${libhdf5name%%.*}
        ext=${libhdf5name#$base}
        ln -s ${libhdf5name} ${prefix}/lib/libhdf5${ext}
    fi
fi

# We want libhdf5 to use OUR libz, so we force it to:
if [[ ${target} == *linux* ]]; then
    for f in ${prefix}/lib/lib{sz,aec,hdf5}*; do
        patchelf --replace-needed $(basename h5py/${LIBSDIR}/libz*.${dlext}*) libz.${dlext}.1 ${f}
    done
elif [[ ${target} == *apple* ]]; then
    for f in ${prefix}/lib/lib{sz,aec,hdf5}*; do
        install_name_tool -change $(basename h5py/${LIBSDIR}/libz*.${dlext}*) libz.1.${dlext} ${f}
    done
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
    LibraryProduct(prefix, ["libhdf5", "hdf5"], :libhdf5),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.4/build_Zlib.v1.2.11.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

