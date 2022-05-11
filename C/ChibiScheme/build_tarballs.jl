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

# apply chibi-scheme#830
patch CMakeLists.txt <<EOF
@@ -209,0 +210,3 @@ endif()
+# when cross-compiling, we need to use a separately built chibi-scheme executable:
+set(BOOTSTRAP \${bootstrap} CACHE FILEPATH "chibi-scheme path for bootstrapping")
+
@@ -225 +228 @@ function(add_stubs_library stub)
-        COMMAND \${bootstrap} \${chibi-ffi} \${stubfile} \${stubout}
+        COMMAND \${BOOTSTRAP} \${chibi-ffi} \${stubfile} \${stubout}
@@ -384 +387 @@ foreach(e \${chibi-scheme-tests})
-        COMMAND chibi-scheme -I \${CMAKE_CURRENT_BINARY_DIR}/lib tests/\${e}.scm
+        COMMAND \${BOOTSTRAP} -I \${CMAKE_CURRENT_BINARY_DIR}/lib tests/\${e}.scm
@@ -389 +392 @@ add_test(NAME r5rs-test
-    COMMAND chibi-scheme -I \${CMAKE_CURRENT_BINARY_DIR}/lib -xchibi tests/r5rs-tests.scm
+    COMMAND \${BOOTSTRAP} -I \${CMAKE_CURRENT_BINARY_DIR}/lib -xchibi tests/r5rs-tests.scm
@@ -429 +432 @@ foreach(e \${testlibs})
-        COMMAND chibi-scheme -I \${CMAKE_CURRENT_BINARY_DIR}/lib
+        COMMAND \${BOOTSTRAP} -I \${CMAKE_CURRENT_BINARY_DIR}/lib
@@ -465 +468 @@ add_custom_command(OUTPUT chibi.img
-    COMMAND chibi-scheme -I \${CMAKE_CURRENT_BINARY_DIR}/lib -mchibi.repl
+    COMMAND \${BOOTSTRAP} -I \${CMAKE_CURRENT_BINARY_DIR}/lib -mchibi.repl
@@ -469 +472 @@ add_custom_command(OUTPUT red.img
-    COMMAND chibi-scheme -I \${CMAKE_CURRENT_BINARY_DIR}/lib -xscheme.red -mchibi.repl
+    COMMAND \${BOOTSTRAP} -I \${CMAKE_CURRENT_BINARY_DIR}/lib -xscheme.red -mchibi.repl
@@ -473 +476 @@ add_custom_command(OUTPUT snow.img
-    COMMAND chibi-scheme -I \${CMAKE_CURRENT_BINARY_DIR}/lib
+    COMMAND \${BOOTSTRAP} -I \${CMAKE_CURRENT_BINARY_DIR}/lib
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
