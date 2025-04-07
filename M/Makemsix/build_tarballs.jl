# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Makemsix"
version = v"1.7.133"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mozilla/msix-packaging.git",
              "be7e5b303ca51e22f74d539b0b62cd361e33e4de"),
]


# Script that will adapt to each platform
script = raw"""
    mkdir $WORKSPACE/tmp
    cp -r $WORKSPACE/srcdir/msix-packaging $WORKSPACE/tmp/msix-packaging
    cd $WORKSPACE/tmp/msix-packaging

    # Update C++ standard to 17 for all platforms
    sed -i 's/set(CMAKE_CXX_STANDARD 14)/set(CMAKE_CXX_STANDARD 17)/' CMakeLists.txt

    mkdir .vs
    cd .vs

    # Platform-specific configuration
    if [[ "${target}" == *"-apple-darwin"* ]]; then
        # macOS specific configuration (x86_64-apple-darwin or aarch64-apple-darwin)
        sed -i.bak '/define fdopen.*NULL.*No fdopen/d' /workspace/tmp/msix-packaging/lib/zlib/zutil.h
        sed -i.bak '/define fdopen.*_fdopen/d' /workspace/tmp/msix-packaging/lib/zlib/zutil.h

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
          -DICU_ROOT=/workspace/destdir \
          -DMSIX_SAMPLES=on \
          -DMSIX_TESTS=off \
          -DMACOS=on \
          -DCMAKE_OSX_SYSROOT=${SYSROOT} \
          -DCOREFOUNDATION_LIBRARY=${CF_FRAMEWORK} \
          -DFOUNDATION_LIBRARY=${FOUNDATION_FRAMEWORK} \
          -DCMAKE_SHARED_LINKER_FLAGS="-Wl,-install_name,@rpath/libmsix.dylib" \
          -DCMAKE_SHARED_LIBRARY_SUFFIX=".dylib" \
          ..

        sed -i 's/-Wl,-soname,[^ ]*//g' $(find /workspace/tmp/msix-packaging/.vs -name "link.txt")
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
          -DLINUX=on"

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

    make

    cd $WORKSPACE/tmp/msix-packaging
    install_license LICENSE 
    install -Dvm 755 .vs/bin/makemsix "${bindir}/makemsix${exeext}"
    
    # Handle library installation based on platform
    if [[ "${target}" == *"-apple-darwin"* ]]; then
        install -Dvm 755 .vs/lib/libmsix.so "${libdir}/libmsix.dylib"
    elif [[ "${target}" == *"-linux-"* ]]; then
        # Both glibc and musl use .so extension
        install -Dvm 755 .vs/lib/libmsix.so "${libdir}/libmsix.so"
    else
        echo "Unsupported platform for library installation: ${target}"
        exit 1
    fi
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
#    Dependency("OpenSSL_jll", compat="1.1.1"),
#    Dependency("Zlib_jll", compat="1.2.11"),
#    Dependency("Xerces_jll", compat="3.2.4"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"11")
