# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TurboPFor"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/powturbo/TurboPFor-Integer-Compression.git", "43fb0b2abaef27f6753f4494ffff638c3002f24c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd TurboPFor-Integer-Compression/
make -j${nprocs}
cd ..
cp -r TurboPFor-Integer-Compression $WORKSPACE/destdir/
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    FileProduct("TurboPFor-Integer-Compression/bitpack_avx2.o", :bitpack_avx2),
    FileProduct("TurboPFor-Integer-Compression/icapp.o", :icapp_obj),
    FileProduct("TurboPFor-Integer-Compression/bitutil.o", :bitutil),
    FileProduct("TurboPFor-Integer-Compression/fp.o", :fp),
    FileProduct("TurboPFor-Integer-Compression/vsimple.o", :vsimple),
    FileProduct("TurboPFor-Integer-Compression/eliasfano.o", :eliasfano),
    FileProduct("TurboPFor-Integer-Compression/bitpack_sse.o", :bitpack_sse),
    FileProduct("TurboPFor-Integer-Compression/vp4c_avx2.o", :vp4c_avx2),
    FileProduct("TurboPFor-Integer-Compression/transpose_sse.o", :transpose_sse),
    FileProduct("TurboPFor-Integer-Compression/transpose.o", :transpose_obj),
    FileProduct("TurboPFor-Integer-Compression/vint.o", :vint),
    FileProduct("TurboPFor-Integer-Compression/trled.o", :trled),
    FileProduct("TurboPFor-Integer-Compression/vp4c_sse.o", :vp4c_sse),
    ExecutableProduct("icapp", :icapp, "TurboPFor-Integer-Compression"),
    FileProduct("TurboPFor-Integer-Compression/vp4c.o", :vp4c),
    FileProduct("TurboPFor-Integer-Compression/v8.o", :v8),
    FileProduct("TurboPFor-Integer-Compression/vp4d.o", :vp4d),
    FileProduct("TurboPFor-Integer-Compression/bitunpack_sse.o", :bitunpack_sse),
    FileProduct("TurboPFor-Integer-Compression/vp4d_sse.o", :vp4d_sse),
    FileProduct("TurboPFor-Integer-Compression/bitunpack.o", :bitunpack),
    FileProduct("TurboPFor-Integer-Compression/bitunpack_avx2.o", :bitunpack_avx2),
    FileProduct("TurboPFor-Integer-Compression/vp4d_avx2.o", :vp4d_avx2),
    FileProduct("TurboPFor-Integer-Compression/transpose_avx2.o", :transpose_avx2),
    FileProduct("TurboPFor-Integer-Compression/trlec.o", :trlec),
    FileProduct("TurboPFor-Integer-Compression/bitpack.o", :bitpack)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8.1.0")
