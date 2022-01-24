# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GoogleSparseHash"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Andersen98/sparsehash-c11.git", "24e94b66249466f71f67a54a96247d99b8dcceb8")
]


script = raw"""
cd sparsehash-*
install_license LICENSE

mkdir ${prefix}/include
mv src/sparsehash ${prefix}/include/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

products = Product[
    FileProduct("include/sparsehash/dense_hash_map", :dense_hash_map),
    FileProduct("include/sparsehash/dense_hash_set", :dense_hash_set),
    FileProduct("include/sparsehash/sparse_hash_map", :sparse_hash_map),
    FileProduct("include/sparsehash/sparse_hash_set", :sparse_hash_set),
    FileProduct("include/sparsehash/sparsetable", :sparsetable),
    FileProduct("include/sparsehash/traits", :traits),
    FileProduct("include/sparsehash/internal/densehashtable.h", :densehashtable_h),
    FileProduct("include/sparsehash/internal/hashtable-common.h", :hashtable_common_h),
    FileProduct("include/sparsehash/internal/libc_allocator_with_realloc.h", :libc_allocator_with_realloc_h),
    FileProduct("include/sparsehash/internal/sparsehashtable.h", :sparsehashtable_h)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6.1.0")
