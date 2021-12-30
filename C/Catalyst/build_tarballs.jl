# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Catalyst"
version = v"0.1.0"
sources = [
    GitSource("https://gitlab.kitware.com/paraview/catalyst", 
	      "16dc369855a7c29bb00829cf8ecb16fa3b7ebd4b")
]

script = raw"""
cd ${WORKSPACE}/srcdir/catalyst*
rm -rf build && mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCATALYST_BUILD_SHARED_LIBS=ON \
      -DCATALYST_BUILD_STUB_IMPLEMENTATION=ON \
      -DCATALYST_BUILD_TESTING=OFF \
      -DCATALYST_BUILD_TOOLS=ON \
      -DCATALYST_USE_MPI=OFF \
      ..
make -j${nproc}
make install
# install catalyst-replay to bindir
mkdir -vp $bindir
cp -v ./bin/catalyst_replay* $bindir
"""

# Paraview / Catalyst only supports x86_64 builds for Linux, Windows
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),
]
platforms = expand_cxxstring_abis(platforms)

# The stub impl has the wrong extension .so for darwin builds, need to fix upstream
products = [
    LibraryProduct("libcatalyst", :libcatalyst),
    ExecutableProduct("catalyst_replay", :catalyst_replay_exe),
    # LibraryProduct("libcatalyst-stub", Symbol("libcatalyst-stub"), ["lib/catalyst"]),
]

dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
	       julia_compat="1.6", preferred_gcc_version=v"5")
