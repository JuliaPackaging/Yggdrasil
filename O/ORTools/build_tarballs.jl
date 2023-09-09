# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "ORTools"
version = v"9.7"

# Collection of sources required to build this package
sources = [
    GitSource("https://github.com/google/or-tools.git",
              "6fa02e157a5c91067b7d7b88629472b9ed461193"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
# Prepare the source directory.
cd $WORKSPACE/srcdir/or-tools*
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/cmake_dependencies_CMakeLists.txt.patch"
mkdir build
cmake --version

# Make the host compile tools easily accessible when cross-compiling.
# Otherwise, CMake will use the cross-compiler for host tools.
export AR=$HOSTAR
export AS=$HOSTAS
export CC=$HOSTCC
export CXX=$HOSTCXX
export DSYMUTIL=$HOSTDSYMUTIL
export FC=$HOSTFC
export includedir=$host_includedir
export libdir=$host_libdir
export LIPO=$HOSTLIPO
export LD=$HOSTLD
export NM=$HOSTNM
export OBJCOPY=$HOSTOBJCOPY
export OBJDUMP=$HOSTOBJDUMP
export RANLIB=$HOSTRANLIB
export READELF=$HOSTREADELF
export STRIP=$HOSTSTRIP

# Build OR-Tools.
cmake -S. -Bbuild \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_DEPS:BOOL=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_EXAMPLES:BOOL=OFF \
    -DBUILD_SAMPLES:BOOL=OFF \
    -DUSE_SCIP:BOOL=OFF \
    -DUSE_HIGHS:BOOL=OFF \
    -DUSE_COINOR:BOOL=OFF \
    -DUSE_GLPK:BOOL=OFF
cmake --build build
cmake --build build --target install

# Automatically generate the Julia bindings.
echo $PATH
ls /cache/julia-buildkite-plugin/julia_installs/bin/linux/x64/1.7/julia-1.7-latest-linux-x86_64 | true
""" * "$(Base.julia_cmd()) -e 'using InteractiveUtils; versioninfo()'"

#=
if [[ "$MACHTYPE" == *musl ]]
then
  curl -o julia-1.9.3.tar.gz https://julialang-s3.julialang.org/bin/musl/x64/1.9/julia-1.9.3-musl-x86_64.tar.gz
else
  curl -o julia-1.9.3.tar.gz https://julialang-s3.julialang.org/bin/linux/x64/1.9/julia-1.9.3-linux-x86_64.tar.gz
fi
tar -xvf julia-1.9.3.tar.gz
julia-1.9.3/bin/julia -e 'using InteractiveUtils; versioninfo()'
=#
#=
julia -e 'using InteractiveUtils; versioninfo()'
=#

# TODO: generate with ProtoBuf.jl.
#     julia -e "using ProtoBuf; protojl()" 

platforms = [
    Platform("x86_64", "linux"),
    # Platform("aarch64", "linux"),   # Abseil uses -march for some files.
    # Platform("x86_64", "macos"),    # Requires Clang 16+.
    # Platform("aarch64", "macos"),   # Abseil uses -march for some files.
    # Platform("x86_64", "freebsd"),  # Requires Clang 16+.
    # Platform("x86_64", "windows"),  # Requires dlfcn.h.
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libortools", :libortools),
]

# Dependencies that must be installed before this package can be built
dependencies = [Dependency("ProtoBuf")]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"12", preferred_llvm_version=v"16", julia_compat="1.6")
