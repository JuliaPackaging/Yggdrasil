# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MAGEMin"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ComputationalThermodynamics/MAGEMin.git", "032116744f3df05b5a2999c2eb39689c831cf4c7"),
    ArchiveSource("https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v3.10.0.tar.gz", "328c1bea493a32cac5257d84157dc686cc3ab0b004e2bea22044e0a59f6f8a19"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
ls
cd lapack-3.10.0/LAPACKE/
cmake ../ -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DLAPACKE=ON -DBUILD_SHARED_LIBS=ON
make lapacke -j${nproc}
make install
cd ../../MAGEMin/
 make CC=$CC CCFLAGS="-Wall -O3 -g -fPIC -std=c99" LIBS="-L/$prefix/libs -lm -llapacke -lnlopt -lmpi" INC=-I$prefix/include lib
cp libMAGEMin.dylib $prefix/lib
cp src/*.h $prefix/include/
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "macos"; ),
    Platform("x86_64", "freebsd"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libMAGEMin", :MAGEMin_library)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="MPICH_jll", uuid="7cb0a576-ebde-5e09-9194-50597f1243b4"))
    Dependency(PackageSpec(name="NLopt_jll", uuid="079eb43e-fd8e-5478-9966-2cf3e3edb778"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
