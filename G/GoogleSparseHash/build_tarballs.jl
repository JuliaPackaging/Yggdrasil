# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GoogleSparseHash"
version = v"2.11.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sparsehash/sparsehash-c11.git", "edd6f1180156e76facc1c0449da245208ab39503")
]


script = raw"""
cd sparsehash-*
install_license LICENSE

mkdir ${prefix}/include
mv sparsehash ${prefix}/include/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

products = [
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
