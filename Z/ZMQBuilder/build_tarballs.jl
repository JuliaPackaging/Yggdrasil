using BinaryBuilder

# Collection of sources required to build ZMQ
sources = [
    "https://github.com/zeromq/libzmq.git" =>
    "2cb1240db64ce1ea299e00474c646a2453a8435b", # v4.3.1
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/libzmq

if [[ ${target} == x86_64-linux-musl ]] && [[ $(gcc --version | head -1 | awk '{ print $3 }') == "4.8.5" ]]; then

cat > mm_malloc.patch << 'END'
--- mm_malloc.h
+++ mm_malloc.h
@@ -31,7 +31,7 @@
 #ifndef __cplusplus
 extern int posix_memalign (void **, size_t, size_t);
 #else
-extern "C" int posix_memalign (void **, size_t, size_t) throw ();
+extern "C" int posix_memalign (void **, size_t, size_t);
 #endif

 static __inline void *
END

cd /opt/x86_64-linux-musl/lib/gcc/x86_64-linux-musl/4.8.5/include/

patch < "${WORKSPACE}/srcdir/libzmq/mm_malloc.patch"

cd $WORKSPACE/srcdir/libzmq

fi

sh autogen.sh
./configure --prefix=$prefix --host=${target} \
    --without-docs --disable-libunwind --disable-perf --disable-Werror \
    --disable-eventfd --without-gcov --disable-curve-keygen \
    CXXFLAGS="-g -O2 -fms-extensions"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms() # build on all supported platforms
platforms = expand_gcc_versions(platforms)

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libzmq", :libzmq),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, "ZMQ", v"4.3.1", sources, script, platforms, products, dependencies)
