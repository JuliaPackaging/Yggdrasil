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

    apk del cmake

    # Overriding vendored dependencies
    cp ../lib/CMakeLists.txt lib/CMakeLists.txt
    cp ../src/msix/PAL/Signature/OpenSSL/SignatureValidator.cpp src/msix/PAL/Signature/OpenSSL/SignatureValidator.cpp 

    # Platform-specific options
    PLATFORM_OPTIONS=""
    
    if [[ "${target}" == *"-apple-darwin"* ]]; then
        # macOS-specific options
        PLATFORM_OPTIONS="-DMACOS=on"

    elif [[ "${target}" == *"-linux-"* ]]; then
        # Linux-specific options
        PLATFORM_OPTIONS="-DLINUX=on"

    elif [[ "${target}" == "x86_64-w64-mingw32" ]]; then
        # Windows-specific options
        find . -name "CMakeLists.txt" -type f -exec sed -i 's/set(CMAKE_CXX_STANDARD 14)/set(CMAKE_CXX_STANDARD 17)/' {} \;

        # Apply Windows-specific patches
        cp ../src/msix/CMakeLists.txt src/msix/CMakeLists.txt
        cp ../src/msix/PAL/FileSystem/Win32/DirectoryObject.cpp src/msix/PAL/FileSystem/Win32/DirectoryObject.cpp
        cp ../src/inc/internal/UnicodeConversion.hpp src/inc/internal/UnicodeConversion.hpp
        cp ../src/inc/public/MSIXWindows.hpp src/inc/public/MSIXWindows.hpp # optional, eliminates warnings

        sed -i 's/static constexpr const IID IID_##name/inline constexpr const IID IID_##name/' src/inc/public/AppxPackaging.hpp
        sed -i 's/#ifdef WIN32/#if defined(WIN32) \&\& !defined(__MINGW32__)/' src/inc/public/AppxPackaging.hpp
        sed -i 's/const PfnDliHook __pfnDliFailureHook2 = MsixDelayLoadFailureHandler;//' src/msix/common/Exceptions.cpp

        # Fix case-sensitive includes for Windows
        find src -type f \( -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" \) -exec sed -i 's/#include "UnKnwn.h"/#include "unknwn.h"/g' {} \;
        find src -type f \( -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" \) -exec sed -i 's/#include "Unknwn.h"/#include "unknwn.h"/g' {} \;
        find src -type f \( -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" \) -exec sed -i 's/#include "Objidl.h"/#include "objidl.h"/g' {} \;

        # Windows-specific compiler flags
        export LDFLAGS="-L${libdir}"
        export CXXFLAGS="$CXXFLAGS -include $WORKSPACE/srcdir/src/inc/compat/msix_win_api_fixes.h"

        PLATFORM_OPTIONS="-DWIN32=on"
    fi

    # Run cmake with common options + platform-specific options
    cmake -B build \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DSKIP_BUNDLES=on \
        -DUSE_VALIDATION_PARSER=on \
        -DMSIX_PACK=on \
        -DMSIX_SAMPLES=on \
        -DMSIX_TESTS=off \
        -DXML_PARSER=xerces \
        -DCRYPTO_LIB=openssl \
        -DCMAKE_PREFIX_PATH=${prefix} \
        -DBUILD_SHARED_LIBS=ON \
        -DUSE_MSIX_SDK_ZLIB=on \
        -DOPENSSL_ROOT_DIR="${prefix}" \
        -DOPENSSL_CRYPTO_LIBRARY=${libdir}/libcrypto.${dlext} \
        -DOPENSSL_SSL_LIBRARY=${libdir}/libssl.${dlext} \
        ${PLATFORM_OPTIONS} \
        .
    
    # Build only what we need
    make -j${nproc} -C build/src

    # Install license and binary
    install_license LICENSE 
    install -Dvm 755 "build/bin/makemsix${exeext}" "${bindir}/makemsix${exeext}"

    # Platform-specific library installation
    if [[ "${target}" == "x86_64-w64-mingw32" ]]; then
        install -Dvm 755 build/lib/libmsix.* "${libdir}/"
        install -Dvm 755 build/bin/libmsix.* "${libdir}/"
        install -Dvm 755 build/bin/libmsix.* "${bindir}/"
    else
        install -Dvm 755 build/lib/libmsix.* "${libdir}/libmsix.${dlext}"
    fi
"""

platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("makemsix", :makemsix),
    LibraryProduct("libmsix", :libmsix),
]

dependencies = [
    Dependency("fts_jll", compat="1.2.7"),
    Dependency("Zlib_jll", compat="1.2.13"),
    Dependency("Xerces_jll", compat="3.2.4"),
    Dependency("OpenSSL_jll", compat="3.0.16"),
    HostBuildDependency(PackageSpec(; name="CMake_jll", version=v"3.31.6")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"11")
