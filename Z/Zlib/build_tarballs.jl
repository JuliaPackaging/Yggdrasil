using BinaryBuilder
using BinaryBuilderBase: sanitize

# zlib version
name = "Zlib"
version = v"1.3"

# Collection of sources required to build zlib
sources = [
    # use Git source because zlib has a track record of deleting release tarballs of old versions
    GitSource("https://github.com/madler/zlib.git",
              "09155eaa2f9270dc4ed1fa13e2b4b2613e6e4851"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/zlib*
mkdir build && cd build
if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi
# We use `-DUNIX=true` to ensure that it is always named `libz` instead of `libzlib` or something ridiculous like that.
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DUNIX=true \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    ..
make install -j${nproc}
install_license ../README
"""

# We enable experimental platforms as this is a core Julia dependency
platforms = supported_platforms(;experimental=true)
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

# The products that we will ensure are always built
products = [
    LibraryProduct("libz", :libz),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("LLVMCompilerRT_jll"; platforms=filter(p -> sanitize(p) == "memory", platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.9")
