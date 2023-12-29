using BinaryBuilder

name = "GLFW"
version = v"3.3.9"

# Collection of sources required to build glfw
sources = [
    ArchiveSource("https://github.com/glfw/glfw/releases/download/$(version)/glfw-$(version).zip",
                  "55261410f8c3a9cc47ce8303468a90f40a653cd8f25fb968b12440624fb26d08")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/glfw-*/
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DGLFW_BUILD_EXAMPLES=false \
    -DGLFW_BUILD_TESTS=false \
    -DGLFW_BUILD_DOCS=OFF
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct(["libglfw", "glfw3"], :libglfw)
]

x11_platforms = filter(p->Sys.islinux(p) || Sys.isfreebsd(p), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"; platforms=x11_platforms),
    Dependency("Libglvnd_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXcursor_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXi_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXinerama_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXrandr_jll"; platforms=x11_platforms),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
