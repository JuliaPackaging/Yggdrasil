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

# Fix case of some Windows headers
atomic_patch -p1 ../patches/windows_headers_case.patch

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
    ZED_CAMERA=0

mkdir -p "${libdir}"
cp libdarknet.${dlext} "${libdir}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
#platforms = supported_platforms(exclude=[Windows(:i686),Windows(:x86_64)])

# The products that we will ensure are always built
products = [
    LibraryProduct("libdarknet", :libdarknet),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
