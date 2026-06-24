# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Catalyst"
version = v"2.0.0"
sources = [
    GitSource("https://gitlab.kitware.com/paraview/catalyst", 
	      "ed6151a298c6bcc888353e2bdf92a40e6ed8de30")
]

script = raw"""
cd ${WORKSPACE}/srcdir/catalyst*
apk del cmake
cmake -G Ninja \
      -B build \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCATALYST_BUILD_TESTING=OFF \
      .
cmake --build build --parallel ${nproc}
cmake --install build
# install catalyst-replay to bindir
mkdir -vp $bindir
install -Dvm 755 ./build/bin/catalyst_replay${exeext} -t ${bindir}
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

dependencies = [
    HostBuildDependency(PackageSpec(; name="CMake_jll", version = v"3.30.2+0"))
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
	       julia_compat="1.6", preferred_gcc_version=v"5")
