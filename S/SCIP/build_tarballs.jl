# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SCIP"
version = v"0.1.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://scip.zib.de/download/release/scipoptsuite-7.0.3.tgz", "5af5185a6e60cc62d1a89e3ac4fe22d32351a5158c2c04a95e180e76eb98cc07"),
]


# bliss script, ignored for now
script_bliss = raw"""
cd $WORKSPACE/srcdir
cd bliss
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
cd $WORKSPACE/srcdir
"""

# Bash recipe for building across all platforms
script = raw"""
cd scipoptsuite*
mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix\
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}\
  -DCMAKE_BUILD_TYPE=Release\
  -DPAPILO=0\
  -DZIMPL=OFF\
  -DGCG=0\
  -DREADLINE=OFF\
  -DBOOST=off\
  -DSYM=bliss\
  -DIPOPT_DIR=${prefix} -DIPOPT_LIBRARIES=${libdir} ..
make -j${nproc}
make install

mkdir -p ${prefix}/share/licenses/SCIP
for dir in papilo scip soplex; do
    cp $WORKSPACE/srcdir/scipoptsuite*/${dir}/COPYING ${prefix}/share/licenses/SCIP/LICENSE_${dir}
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("armv7l", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("armv7l", "linux"; libc="musl"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "freebsd"),
    Platform("i686", "windows"),
    Platform("x86_64", "windows"),
]

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libscip", :libscip),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="bliss_jll", uuid="508c9074-7a14-5c94-9582-3d4bc1871065")),
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"), v"6.1.2"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="Ipopt_jll", uuid="9cc047cb-c261-5740-88fc-0cf96f7bdcc7")),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0")
