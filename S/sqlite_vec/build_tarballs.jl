# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "sqlite_vec"
version = v"0.1.6"

# Collection of sources required to complete build
sources = [
    # Official amalgamation release artifact
    ArchiveSource("https://github.com/asg017/sqlite-vec/releases/download/v0.1.6/sqlite-vec-0.1.6-amalgamation.tar.gz",
                  "99b6ec36e9d259d91bd6cb2c053c3a7660f8791eaa66126c882a6a4557e57d6a"),
    # SQLite amalgamation for headers (sqlite3.h, sqlite3ext.h)
    ArchiveSource("https://www.sqlite.org/2024/sqlite-amalgamation-3450300.zip",
                  "ea170e73e447703e8359308ca2e4366a3ae0c4304a8665896f068c736781c651"),
    # License files
    FileSource("https://raw.githubusercontent.com/asg017/sqlite-vec/v0.1.6/LICENSE-MIT",
               "6ce72bbe12d975bd5286e5ab0a064c069693300c47bccbc57bec18485f1621ea"),
    FileSource("https://raw.githubusercontent.com/asg017/sqlite-vec/v0.1.6/LICENSE-APACHE",
               "a38070a94d4afd9cd710e3ce67bd1de78097cfe1784c1f0109ac95d3c196bfdc"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

# Move SQLite headers to vendor directory (amalgamation extracts to srcdir directly)
mkdir -p vendor
cp sqlite-amalgamation-3450300/sqlite3.h vendor/
cp sqlite-amalgamation-3450300/sqlite3ext.h vendor/

# sqlite-vec.h is already generated in the amalgamation release

# Fix invalid u_int typedefs in amalgamation (breaks musl)
sed -i \
    -e '/typedef u_int8_t uint8_t;/d' \
    -e '/typedef u_int16_t uint16_t;/d' \
    -e '/typedef u_int64_t uint64_t;/d' \
    sqlite-vec.c

# Fix NEON vabdq_s8 typing for armv8
sed -i \
    -e 's/int8x16_t diff1 = vabdq_s8(v1, v2);/uint8x16_t diff1 = (uint8x16_t) vabdq_s8(v1, v2);/' \
    -e 's/int8x16_t diff2 = vabdq_s8(v1, v2);/uint8x16_t diff2 = (uint8x16_t) vabdq_s8(v1, v2);/' \
    -e 's/int8x16_t diff3 = vabdq_s8(v1, v2);/uint8x16_t diff3 = (uint8x16_t) vabdq_s8(v1, v2);/' \
    -e 's/int8x16_t diff4 = vabdq_s8(v1, v2);/uint8x16_t diff4 = (uint8x16_t) vabdq_s8(v1, v2);/' \
    -e 's/int8x16_t diff = vabdq_s8(v1, v2);/uint8x16_t diff = (uint8x16_t) vabdq_s8(v1, v2);/' \
    -e 's/acc1 = vaddq_s32(acc1, vpaddlq_u16(vpaddlq_u8(diff1)));/acc1 = vaddq_s32(acc1, vreinterpretq_s32_u32(vpaddlq_u16(vpaddlq_u8(diff1))));/' \
    -e 's/acc2 = vaddq_s32(acc2, vpaddlq_u16(vpaddlq_u8(diff2)));/acc2 = vaddq_s32(acc2, vreinterpretq_s32_u32(vpaddlq_u16(vpaddlq_u8(diff2))));/' \
    -e 's/acc3 = vaddq_s32(acc3, vpaddlq_u16(vpaddlq_u8(diff3)));/acc3 = vaddq_s32(acc3, vreinterpretq_s32_u32(vpaddlq_u16(vpaddlq_u8(diff3))));/' \
    -e 's/acc4 = vaddq_s32(acc4, vpaddlq_u16(vpaddlq_u8(diff4)));/acc4 = vaddq_s32(acc4, vreinterpretq_s32_u32(vpaddlq_u16(vpaddlq_u8(diff4))));/' \
    -e 's/acc1 = vaddq_s32(acc1, vpaddlq_u16(vpaddlq_u8(diff)));/acc1 = vaddq_s32(acc1, vreinterpretq_s32_u32(vpaddlq_u16(vpaddlq_u8(diff))));/' \
    sqlite-vec.c

# Set up SIMD flags based on target architecture
SIMD_FLAGS=""
if [[ "${target}" == x86_64-* ]]; then
    SIMD_FLAGS="-mavx -DSQLITE_VEC_ENABLE_AVX"
elif [[ "${target}" == aarch64-* ]]; then
    SIMD_FLAGS="-DSQLITE_VEC_ENABLE_NEON"
fi

# Build the loadable extension
mkdir -p dist

if [[ "${target}" == *-mingw* ]]; then
    # Windows build with MinGW
    ${CC} \
        -shared \
        -Wall -Wextra \
        -Ivendor/ \
        -O3 \
        -std=gnu99 \
        ${SIMD_FLAGS} \
        sqlite-vec.c \
        -o dist/vec0.${dlext}
else
    # Unix build (Linux, macOS, FreeBSD)
    ${CC} \
        -fPIC -shared \
        -Wall -Wextra \
        -Ivendor/ \
        -O3 \
        -std=gnu99 \
        ${SIMD_FLAGS} \
        sqlite-vec.c \
        -lm \
        -o dist/vec0.${dlext}
fi

# Build the static library
${CC} -Ivendor/ ${SIMD_FLAGS} -DSQLITE_CORE -DSQLITE_VEC_STATIC -std=gnu99 \
    -O3 -c sqlite-vec.c -o dist/sqlite-vec.o
ar rcs dist/libsqlite_vec.a dist/sqlite-vec.o

# Install products
install -Dm755 dist/vec0.${dlext} ${libdir}/vec0.${dlext}
install -Dm644 dist/libsqlite_vec.a ${prefix}/lib/libsqlite_vec.a
install -Dm644 sqlite-vec.h ${includedir}/sqlite-vec.h

# Install license
install_license LICENSE-MIT LICENSE-APACHE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("vec0", :libvec0),
    FileProduct("lib/libsqlite_vec.a", :libsqlite_vec_static),
    FileProduct("include/sqlite-vec.h", :sqlite_vec_h),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
