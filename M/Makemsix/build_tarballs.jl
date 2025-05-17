# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Makemsix"
version = v"1.7.241"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/microsoft/msix-packaging.git",
              "efeb9dad695a200c2beaddcba54a52c8320bd135"),
    DirectorySource(joinpath(@__DIR__, "patches"))
]


# Script that will adapt to each platform
script = raw"""
    cd $WORKSPACE/srcdir/msix-packaging

    # Update C++ standard to 17
    sed -i 's/set(CMAKE_CXX_STANDARD 14)/set(CMAKE_CXX_STANDARD 17)/' CMakeLists.txt
    find . -name "CMakeLists.txt" -type f -exec sed -i 's/set(CMAKE_CXX_STANDARD 14)/set(CMAKE_CXX_STANDARD 17)/' {} \;
    find . -name "CMakeLists.txt" -type f -exec sed -i 's/cmake_minimum_required(VERSION 3.29.0 FATAL_ERROR)/cmake_minimum_required(VERSION 3.21.7)/' {} \;

    cp ../lib/CMakeLists.txt lib/CMakeLists.txt
    cp ../src/msix/PAL/Signature/OpenSSL/SignatureValidator.cpp src/msix/PAL/Signature/OpenSSL/SignatureValidator.cpp 

    mkdir .vs
    cd .vs

    # Set up linker and include paths
    export LDFLAGS="-L${libdir}"
    export CPPFLAGS="-I${includedir}"
    
    # Ensure pkg-config can find our dependencies
    export PKG_CONFIG_PATH="${libdir}/pkgconfig:${prefix}/share/pkgconfig"

    export OPENSSL_ROOT_DIR="${prefix}"
    export OPENSSL_CRYPTO_LIBRARY=${libdir}/libcrypto.${dlext}
    export OPENSSL_SSL_LIBRARY=${libdir}/libssl.${dlext}

    # Platform-specific configuration
    if [[ "${target}" == *"-apple-darwin"* ]]; then

        # Set architecture-specific paths based on target
        if [[ "${target}" == *"aarch64-apple-darwin"* ]]; then
            ARCH="aarch64"
            DARWIN_VER="20"
            OSX_ARCH="arm64"
        else
            ARCH="x86_64"
            DARWIN_VER="14"
            OSX_ARCH="x86_64"
        fi

        SYSROOT="/opt/${ARCH}-apple-darwin${DARWIN_VER}/${ARCH}-apple-darwin${DARWIN_VER}/sys-root"
        CF_FRAMEWORK="${SYSROOT}/System/Library/Frameworks/CoreFoundation.framework"
        FOUNDATION_FRAMEWORK="${SYSROOT}/System/Library/Frameworks/Foundation.framework"

        cmake \
          -DCMAKE_BUILD_TYPE=MinSizeRel \
          -DSKIP_BUNDLES=on \
          -DUSE_VALIDATION_PARSER=on \
          -DUSE_MSIX_SDK_ZLIB=on \
          -DCMAKE_OSX_ARCHITECTURES=${OSX_ARCH} \
          -DMSIX_PACK=on \
          -DMSIX_SAMPLES=on \
          -DMSIX_TESTS=off \
          -DMACOS=on \
          -DCMAKE_OSX_SYSROOT=${SYSROOT} \
          -DCOREFOUNDATION_LIBRARY=${CF_FRAMEWORK} \
          -DFOUNDATION_LIBRARY=${FOUNDATION_FRAMEWORK} \
          -DCMAKE_SHARED_LINKER_FLAGS="-Wl,-install_name,@rpath/libmsix.dylib" \
          -DCMAKE_SHARED_LIBRARY_SUFFIX=".dylib" \
          -DXML_PARSER=xerces \
          -DCRYPTO_LIB=openssl \
          -DCMAKE_PREFIX_PATH=${prefix} \
          -DBUILD_SHARED_LIBS=ON \
          ..

          sed -i 's/-Wl,-soname,[^ ]*//g' $(find /workspace/srcdir/msix-packaging/.vs -name "link.txt")
    elif [[ "${target}" == *"-linux-"* ]]; then
        # Linux specific configuration (both glibc and musl)
        
        if [[ "${target}" == *"linux-musl"* ]]; then
            export CFLAGS="${CFLAGS} -I/workspace/destdir/include"
            export CXXFLAGS="${CXXFLAGS} -I/workspace/destdir/include"
            export LDFLAGS="${LDFLAGS} -L/workspace/destdir/lib -lfts"
        fi


        CMAKE_OPTIONS="-DCMAKE_BUILD_TYPE=MinSizeRel \
          -DSKIP_BUNDLES=on \
          -DUSE_VALIDATION_PARSER=on \
          -DCMAKE_SYSTEM_NAME=Linux \
          -DCMAKE_C_COMPILER=clang \
          -DCMAKE_CXX_COMPILER=clang++ \
          -DMSIX_PACK=on \
          -DICU_ROOT=/workspace/destdir \
          -DMSIX_SAMPLES=on \
          -DMSIX_TESTS=off \
          -DLINUX=on \
          -DXML_PARSER=xerces \
          -DCRYPTO_LIB=openssl \
          -DCMAKE_PREFIX_PATH=${prefix} \
          -DBUILD_SHARED_LIBS=ON"

        # Add aarch64 specific flags
        if [[ "${target}" == *"aarch64-"* ]]; then
            CMAKE_OPTIONS="${CMAKE_OPTIONS} -DCMAKE_SYSTEM_PROCESSOR=aarch64"
            CMAKE_EXE_LINKER_FLAGS="${CMAKE_EXE_LINKER_FLAGS} -latomic"
        else
            CMAKE_OPTIONS="${CMAKE_OPTIONS} -DCMAKE_SYSTEM_PROCESSOR=x86_64"
        fi

        # Handle musl vs glibc
        if [[ "${target}" == *"-linux-musl"* ]]; then
            # Additional options for musl libc if needed
            echo "Building for musl libc"
        else
            echo "Building for glibc"
        fi

        cmake ${CMAKE_OPTIONS} .. 
    fi

    make -j${nproc}

    cd $WORKSPACE/srcdir/msix-packaging
    install_license LICENSE 
    install -Dvm 755 .vs/lib/libmsix.* "${libdir}/libmsix.${dlext}"
    install -Dvm 755 .vs/bin/makemsix "${bindir}/makemsix${exeext}"
"""

platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    #Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("makemsix", :makemsix),
]

dependencies = [
    Dependency("ICU_jll", compat="76.1.0"),
    Dependency("fts_jll", compat="1.2.7"),
    Dependency("Zlib_jll", compat="1.2.13"),
    Dependency("Xerces_jll", compat="3.2.4"),
    Dependency("OpenSSL_jll", compat="3.0.16"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"11")
