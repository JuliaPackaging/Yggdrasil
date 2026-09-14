using BinaryBuilder, Pkg

name = "CaDiCaL"
version = v"3.0.1"

sources = [
    GitSource("https://github.com/arminbiere/cadical.git",
              "c60730422e758ef1cebe7aeddf2dda31c996bf04"),
]

script = raw"""
cd $WORKSPACE/srcdir/cadical

# CaDiCaL's ./configure runs several compiled test binaries to probe
# compiler features, then checks their *output*. That execution step is
# invalid under cross-compilation (e.g. building macOS/Windows binaries
# from this Linux-hosted sandbox) since a foreign-format binary can never
# execute here, regardless of whether the toolchain itself is fine. Most
# of these checks already degrade gracefully on execution failure; two
# are hard 'die's and need patching so configure can proceed. The
# compile-only checks are left untouched.
sed -i "/execution of.*failed/c\\    :  # skip: cannot execute cross-compiled test binary" configure
sed -i 's/die "checking compilation without '\''-std=c++11'\'' failed"/msg "assuming C++11 support (execution check skipped under cross-compilation)"/' configure
sed -i 's/die "checking compilation with '\''-std=c++11'\'' failed"/msg "assuming C++11 support via -std=c++11 (execution check skipped under cross-compilation)"/' configure
mkdir build && cd build
CXX=$CXX ../configure -shared
make -j${nproc} CXX=$CXX libcadical.so

mkdir -p $prefix/lib $prefix/include
# CaDiCaL's makefile always names the output 'libcadical.so' regardless of
# target platform; rename to the platform-correct extension on install.
install -Dvm 755 libcadical.so $prefix/lib/libcadical.$dlext
install -Dvm 644 ../src/ccadical.h $prefix/include/
install_license ../LICENSE
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
]
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libcadical", :libcadical),
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version = v"9",
               julia_compat = "1.6")