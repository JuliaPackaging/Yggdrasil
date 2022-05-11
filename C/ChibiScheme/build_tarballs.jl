using BinaryBuilder

name = "ChibiScheme"
version = v"0.10.1" # NOT OFFICIAL

# Collection of sources required to build NLopt
sources = [
    GitSource("https://github.com/ashinn/chibi-scheme.git",
              "b0735b3ca70620face209c5066898e5e9e1fcf62"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/chibi-scheme

patch CMakeLists.txt <<EOF
@@ -202,10 +202,11 @@ if(BUILD_SHARED_LIBS)
     # is not a generator expression within the actual custom command to process
     # the stubs, as older CMake versions fail to properly construct the dependency
     # on the bootstrap executable from the generator expression.
-    set(bootstrap chibi-scheme)
+    set(_bootstrap chibi-scheme)
 else()
-    set(bootstrap chibi-scheme-bootstrap)
+    set(_bootstrap chibi-scheme-bootstrap)
 endif()
+set(bootstrap ${_bootstrap} CACHE FILEPATH "chibi-scheme path for bootstrapping")
EOF

apk add chibi-scheme

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -Dbootstrap=`which chibi-scheme` \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libchibi-scheme", :libchibischeme),
    FileProduct("share/chibi/init-7.scm", :init_7_scm),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
