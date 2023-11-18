# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "XZ"
version = v"5.4.5"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://tukaani.org/xz/xz-$(version).tar.xz",
                  "da9dec6c12cf2ecf269c31ab65b5de18e8e52b96f35d5bcd08c12b43e6878803"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xz-*
BUILD_FLAGS=(--prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-pic)

# i686 error "configure works but build fails at crc32_x86.S"
# See 4.3 from https://git.tukaani.org/?p=xz.git;a=blob_plain;f=INSTALL;hb=HEAD
if [[ "${target}" == i686-linux-* ]]; then
    BUILD_FLAGS+=(--disable-assembler)
fi

if [[ "${target}" != *-gnu* ]]; then
    ./configure "${BUILD_FLAGS[@]}"
    make -j${nproc}
    make install
else
    STATIC_SHARED_TOGGLE=(--disable-shared --disable-static)
    # Handle error on GNU/Linux:
    #  configure: error:
    #      On GNU/Linux, building both shared and static library at the same time
    #      is not supported if --with-pic or --without-pic is used.
    #      Use either --disable-shared or --disable-static to build one type
    #      of library at a time. If both types are needed, build one at a time,
    #      possibly picking only src/liblzma/.libs/liblzma.a from the static build.
    for TOGGLE in "${STATIC_SHARED_TOGGLE[@]}"; do
        ./configure "${BUILD_FLAGS[@]}" "${TOGGLE[@]}"
        make -j${nproc}
        make install
    done
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("xzdec", :xzdec),
    ExecutableProduct("lzmainfo", :lzmainfo),
    ExecutableProduct("xz", :xz),
    LibraryProduct("liblzma", :liblzma),
    ExecutableProduct("lzmadec", :lzmadec),
    # The static library is needed by libunwind
    FileProduct("lib/liblzma.a", :liblzma_a),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
