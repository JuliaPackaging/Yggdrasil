# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libsingular"
version = v"0.0.10"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Singular/Sources.git", "4c1fc06f2d81e12a8e75a5419444cb157fbe45e9")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
export HOSTCFLAGS=-I$prefix/include
export CFLAGS=-I$prefix/include
export LDFLAGS=-Wl,-rpath,$prefix/lib
export LD_LIBRARY_PATH=$target/lib:$LD_LIBRARY_PATH
export AR=/opt/$target/bin/$target-ar
if [ $target = "x86_64-linux-gnu" ]; then
  mkdir -p $prefix/x86_64-linux-gnu/lib/../lib64;
  cp /opt/x86_64-linux-gnu/x86_64-linux-gnu/lib64/libstdc++.la /workspace/destdir/x86_64-linux-gnu/lib/../lib64/;
  cp /opt/x86_64-linux-gnu/x86_64-linux-gnu/lib64/libstdc++.so /workspace/destdir/x86_64-linux-gnu/lib/../lib64/;
fi
cd Sources
./autogen.sh
cd ..
mkdir Singular_build
cd Singular_build
../Sources/configure --prefix=$prefix --host=$target --libdir=$prefix/lib \
    --with-libparse \
    --disable-static \
    --enable-p-procs-static \
    --disable-p-procs-dynamic \
    --disable-gfanlib \
    --enable-shared \
    --with-readline=no \
    --with-gmp=$prefix \
    --with-flint=$prefix \
    --with-ntl=no \
    --without-python
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc)
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libomalloc", :libomalloc),
    ExecutableProduct("libparse", :libparse),
    LibraryProduct("libsingular_resources", :libsingular_resources),
    ExecutableProduct("Singular", :Singular),
    LibraryProduct("libSingular", :libSingular),
    LibraryProduct("libpolys", :libpolys),
    LibraryProduct("libfactory", :libfactor)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"))
    Dependency(PackageSpec(name="MPFR_jll", uuid="3a97d323-0669-5f0c-9066-3539efd106a3"))
    Dependency(PackageSpec(name="FLINT_jll", uuid="e134572f-a0d5-539d-bddf-3cad8db41a82"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
