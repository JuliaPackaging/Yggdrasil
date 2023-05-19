using BinaryBuilder, Pkg

name = "Vulkan_Loader"
version = v"1.3.243"

sources = [
    GitSource("https://github.com/KhronosGroup/Vulkan-Loader.git",
              "22407d7804f111fbc0e31fa0db592d658e19ae8b")
    ArchiveSource("https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v10.0.0.tar.bz2",
                  "ba6b430aed72c63a3768531f6a3ffc2b0fde2c57a3b251450dcf489a894f0894")
]

script = raw"""

if [[ "${target}" == *-mingw* ]]; then
    cd $WORKSPACE/srcdir/mingw*/mingw-w64-headers
    ./configure --prefix=/opt/$target/$target/sys-root --enable-sdk=all --host=$target
    make install

    cd ../mingw-w64-crt/
    if [ ${target} == "i686-w64-mingw32" ]; then
        _crt_configure_args="--disable-lib64 --enable-lib32"
    elif [ ${target} == "x86_64-w64-mingw32" ]; then
        _crt_configure_args="--disable-lib32 --enable-lib64"
    fi
    ./configure --prefix=/opt/$target/$target/sys-root --enable-sdk=all --host=$target --enable-wildcard ${_crt_configure_args}
    make -j${nproc}
    make install

    cd ../mingw-w64-libraries/winpthreads
    ./configure --prefix=/opt/$target/$target/sys-root --host=$target --enable-static --enable-shared
    make -j${nproc}
    make install

    cd $WORKSPACE/srcdir
fi

cd Vulkan-Loader

install_license LICENSE.txt

CMAKE_FLAGS=()

# Setup cross-compilation toolchain
CMAKE_FLAGS+=(-DCMAKE_PREFIX_PATH=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})

# Release build
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_LIBDIR=${libdir})

if [[ "${target}" == *-apple-darwin* ]]; then
    CMAKE_FLAGS+=(-DUSE_MASM=OFF)
elif [[ "${target}" == aarch64-linux-* ]]; then
    CMAKE_FLAGS+=(-DUSE_GAS=OFF)
elif [[ "${target}" == *-mingw* ]]; then
    CMAKE_FLAGS+=(-DUSE_MASM=OFF -DENABLE_WERROR=OFF)
fi

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc} install
"""

# X11 is not available on armv6l
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms())

# The products that we will ensure are always built
products = Product[
    LibraryProduct(["libvulkan", "libvulkan-1", "vulkan", "vulkan-1"], :libvulkan)
]

# Some dependencies are needed only on Linux or Linux and FreeBSD
linux = filter(Sys.islinux, platforms)
linux_freebsd = filter(p->Sys.islinux(p)||Sys.isfreebsd(p), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Vulkan_Headers_jll"),
    Dependency("Xorg_libXrandr_jll"; platforms=linux_freebsd),
    Dependency("Xorg_libX11_jll"; platforms=linux_freebsd),
    Dependency("Wayland_jll"; platforms=linux),
    Dependency("xkbcommon_jll"; platforms=linux),
    BuildDependency("Xorg_xorgproto_jll"; platforms=linux_freebsd),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
