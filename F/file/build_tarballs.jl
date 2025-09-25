using BinaryBuilder

name = "file"

version = v"5.45"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/file/file.git",
              "4cbd5c8f0851201d203755b76cb66ba991ffd8be"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/file/

atomic_patch -p1 "${WORKSPACE}/srcdir/patches/fix-version-check.patch"

autoreconf -i -f

# Do native build to get the correct version of `file` locally, as a native build of the
# current version is required for cross compiling. We'll make it statically linked to
# avoid any potential rpath woes.
mkdir build-native && cd build-native
../configure \
    --prefix=$(pwd) \
    --host=${MACHTYPE} \
    --build=${MACHTYPE} \
    --enable-static \
    --disable-shared \
    CC=${CC_BUILD} \
    CXX=${CXX_BUILD} \
    LD=${LD_BUILD}
make -j${nproc}
make install
if [[ $target == *mingw* ]]; then
    # The build system looks for a local version with the same executable extension, so
    # if we're building for Windows then pretend the local version is also .exe
    mv bin/file bin/file.exe
fi
cd ..

# Prepend the installation location of the native build to the PATH so it will get picked
# up by the build system
export PATH="${PWD}/build-native/bin:${PATH}"

# Override the cross compilation check to ensure that builds for x86_64-linux-musl go
# through the same code paths, since they also need the local static build
./configure --prefix=${prefix} --host=${target} --build=${MACHTYPE} cross_compiling=yes
make -j${nproc}
make install

install_license COPYING
"""

platforms = supported_platforms()

products = [
    ExecutableProduct("file", :file),
    LibraryProduct(["libmagic", "libmagic-1"], :libmagic),
    FileProduct("include/magic.h", :magic_h),
]
dependencies = [
    Dependency("Bzip2_jll"),
    Dependency("XZ_jll"),
    Dependency("Zlib_jll"),
    Dependency("GNURX_jll"; compat="2.5.1", platforms=filter(Sys.iswindows, platforms)),
]
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
