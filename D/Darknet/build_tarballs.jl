using BinaryBuilder

# Collection of sources required to build Darknet
name = "Darknet"
version = v"2019.11.15"
sources = [
    "https://github.com/AlexeyAB/darknet/archive/71e835458904f782a905a06d28b4558d9e9830b4.zip" =>
    "d77017462ae49f9ce2540c3e47589e68b2ce565573bf7d2f011b560bc989fbfa",
]

GPU = 0
CUDNN = 0
CUDNN_HALF = 0
OPENCV = 0
DEBUG = 0
OPENMP = 0
LIBSO = 1
ZED_CAMERA = 0

script = """
cd \$WORKSPACE/srcdir/darknet-*

sed -i 's/GPU=0/GPU=$GPU/g' Makefile
sed -i 's/CUDNN=0/CUDNN=$CUDNN/g' Makefile
sed -i 's/CUDNN_HALF=0/CUDNN_HALF=$CUDNN_HALF/g' Makefile
sed -i 's/OPENCV=0/OPENCV=$OPENCV/g' Makefile
sed -i 's/DEBUG=0/DEBUG=$DEBUG/g' Makefile
sed -i 's/OPENMP=0/OPENMP=$OPENMP/g' Makefile
sed -i 's/LIBSO=0/LIBSO=$LIBSO/g' Makefile
sed -i 's/ZED_CAMERA=0/ZED_CAMERA=$ZED_CAMERA/g' Makefile

./configure --prefix=\$prefix --host=\$target
make -j${nproc}
make install
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
