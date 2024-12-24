using BinaryBuilder
using Pkg
using BinaryBuilderBase: sanitize

# zlib version
name = "Zlib"
version = v"1.3.1"

# Collection of sources required to build zlib
sources = [
    # use Git source because zlib has a track record of deleting release tarballs of old versions
    GitSource("https://github.com/madler/zlib.git",
              "51b7f2abdade71cd9bb0e7a373ef2610ec6f9daf"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/zlib*
mkdir build && cd build
if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi
# We use `-DUNIX=true` to ensure that it is always named `libz` instead of `libzlib` or something absolutely absurd like that.
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
platforms = supported_platforms()
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

# The products that we will ensure are always built
products = [
    LibraryProduct("libz", :libz),
]

llvm_version = v"13.0.1"

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(; name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=llvm_version); platforms=filter(p -> sanitize(p)=="memory", platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.9", preferred_llvm_version=llvm_version)

# build trigger: 1
