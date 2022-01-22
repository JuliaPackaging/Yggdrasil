# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "google_sparsehash"
version = v"2.0.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sparsehash/sparsehash-c11.git", "fabeb799894db0762b6bcc0f1fd66937cb9bc037")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir -p sparsehash-c11/build && cd sparsehash-c11/build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
cmake --build . -j${nproc}
cmake --install .
install_license ../LICENSE 
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

#paths_symbols = collect(Iterators.flatten([[(normpath(joinpath(root,file)),(splitext(file)[2]=="") ? Symbol(splitext(file)[1]) : Symbol(splitext(file)[1],"_h")) for file in files] for (root, dirs, files) in walkdir(includedir)]))
    
        

# The products that we will ensure are always built
#products = Product[map(x->FileProduct(x...), paths_symbols)...]

products = Product[
    FileProduct(["include/google/sparsehash/dense_hash_map"], :dense_hash_map),
    FileProduct(["include/google/sparsehash/dense_hash_set"], :dense_hash_set),
    FileProduct(["include/google/sparsehash/sparse_hash_map"], :sparse_hash_map),
    FileProduct(["include/google/sparsehash/sparse_hash_set"], :sparse_hash_set),
    FileProduct(["include/google/sparsehash/sparsetable"], :sparsetable),
    FileProduct(["include/google/sparsehash/traits"], :traits),
    FileProduct(["include/google/sparsehash/internal/densehashtable.h"], :densehashtable_h),
    FileProduct(["include/google/sparsehash/internal/hashtable-common.h"], :hashtable_common_h),
    FileProduct(["include/google/sparsehash/internal/libc_allocator_with_realloc.h"], :libc_allocator_with_realloc_h),
    FileProduct(["include/google/sparsehash/internal/sparsehashtable.h"], :sparsehashtable_h)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.7", preferred_gcc_version = v"6.1.0")
