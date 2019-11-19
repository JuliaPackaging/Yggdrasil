using BinaryBuilder

# Collection of sources required to build Darknet
name = "Darknet"
version = v"2019.11.15"
sources = [
    "https://github.com/AlexeyAB/darknet/archive/71e835458904f782a905a06d28b4558d9e9830b4.zip" =>
    "d77017462ae49f9ce2540c3e47589e68b2ce565573bf7d2f011b560bc989fbfa",
    "./bundled",
]

script = raw"""
cd $WORKSPACE/srcdir/darknet-*

if [[ "${target}" == *-mingw* ]]; then
    # Fix case of some Windows headers
    atomic_patch -p1 ../patches/windows_headers_case.patch
    # Comment out a couple of definitions
    atomic_patch -p1 ../patches/getopt_windows.patch
    # Link against ws2_32 on Windows
    atomic_patch -p1 ../patches/windows_ldflags.patch
    # This makes it work for 64-bit Windows
    atomic_patch -p1 ../patches/gemmc_windows_64bit.patch
fi

if [[ "${target}" = arm* ]] || [[ "${target}" == aarch* ]] || [[ "${target}" == *-mingw* ]]; then
    # Disable AVX on arm, aarch & windows
    export AVXENABLE=0
else
    # Enable everywhere else
    export AVXENABLE=1
fi

# Make sure to have the directories, before building
make obj backup results setchmod
make -j${nproc} libdarknet.${dlext} \
    LIBNAMESO="libdarknet.${dlext}" \
    LIBSO=1 \
    GPU=0 \
    CUDNN=0 \
    CUDNN_HALF=0 \
    OPENCV=0 \
    DEBUG=0 \
    OPENMP=0 \
    ZED_CAMERA=0 \
    AVX=${AVXENABLE}

mkdir -p "${libdir}"
cp libdarknet.${dlext} "${libdir}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libdarknet", :libdarknet),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
