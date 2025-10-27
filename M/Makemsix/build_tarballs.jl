# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Makemsix"
version = v"1.7.241"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/microsoft/msix-packaging.git",
              "efeb9dad695a200c2beaddcba54a52c8320bd135"),
    DirectorySource(joinpath(@__DIR__, "bundled"))
]

# Script that will adapt to each platform
script = raw"""
    cd $WORKSPACE/srcdir/msix-packaging

    apk del cmake

    # Overriding vendored dependencies
    cp ../patches/lib/CMakeLists.txt lib/CMakeLists.txt

    # Fix the use of internal OpenSSL APIs
    sed -i \
        -e '/^#include <crypto\/x509\.h>$/d' \
        -e '/^#include <openssl\/x509\.h>$/ a\
    // Remove internal header include - use only public headers\
    // #include <crypto/x509.h>' \
        -e 's/STACK_OF(X509_EXTENSION) \*exts = cert->cert_info\.extensions;/const STACK_OF(X509_EXTENSION) *exts = X509_get0_extensions(cert);/g' \
        -e 's/STACK_OF(X509_EXTENSION) \*exts = signingCert->cert_info\.extensions;/const STACK_OF(X509_EXTENSION) *exts = X509_get0_extensions(signingCert);/g' \
        -e 's/ctx->error == X509_V_ERR_CERT_HAS_EXPIRED/X509_STORE_CTX_get_error(ctx) == X509_V_ERR_CERT_HAS_EXPIRED/g' \
        -e 's/ctx->error == X509_V_ERR_UNHANDLED_CRITICAL_EXTENSION/X509_STORE_CTX_get_error(ctx) == X509_V_ERR_UNHANDLED_CRITICAL_EXTENSION/g' \
        src/msix/PAL/Signature/OpenSSL/SignatureValidator.cpp

    # Fix case-sensitive includes for Windows (upstream bug)
    find src -type f \( -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" \) \
        -exec sed -i -e 's/#include "UnKnwn.h"/#include "unknwn.h"/g' \
                     -e 's/#include "Unknwn.h"/#include "unknwn.h"/g' \
                     -e 's/#include "Objidl.h"/#include "objidl.h"/g' {} \;

    # Platform-specific options
    PLATFORM_OPTIONS=""
    
    if [[ "${target}" == *"-apple-darwin"* ]]; then
        # macOS-specific options
        PLATFORM_OPTIONS="-DMACOS=on"

    elif [[ "${target}" == *"-linux-"* ]] || [[ "${target}" == *"-freebsd"* ]]; then
        # Linux-specific options
        PLATFORM_OPTIONS="-DLINUX=on"

    elif [[ "${target}" == *"-mingw32" ]]; then
        # MinGW-specific patches
        find . -name "CMakeLists.txt" -type f -exec sed -i 's/set(CMAKE_CXX_STANDARD 14)/set(CMAKE_CXX_STANDARD 17)/' {} \;
      
        awk -i inplace '/if\(WIN32\)/ {count++; if(count==3) { print "if(FALSE) # Original: if(WIN32) - disabled for MinGW compatibility" } else { print $0 } next } {print}' src/msix/CMakeLists.txt 
        cat ../patches/src/msix/CMakeLists.txt >> src/msix/CMakeLists.txt

        cp ../patches/src/inc/internal/UnicodeConversion.hpp src/inc/internal/UnicodeConversion.hpp
        cp ../patches/src/inc/public/MSIXWindows.hpp src/inc/public/MSIXWindows.hpp 

        sed -i 's/static constexpr const IID IID_##name/inline constexpr const IID IID_##name/' src/inc/public/AppxPackaging.hpp
        sed -i 's/#ifdef WIN32/#if defined(WIN32) \&\& !defined(__MINGW32__)/' src/inc/public/AppxPackaging.hpp
        sed -i 's/const PfnDliHook __pfnDliFailureHook2 = MsixDelayLoadFailureHandler;//' src/msix/common/Exceptions.cpp

        sed -i \
            -e 's/void WalkDirectory(const std::string& root, WalkOptions options, Lambda& visitor)/void WalkDirectory(const std::string\& root, WalkOptions options, Lambda visitor)/' \
            -e 's/WIN32_FIND_DATA findFileData = {};/WIN32_FIND_DATAW findFileData = {};/' \
            -e 's/FindFirstFile(reinterpret_cast<LPCWSTR>(utf16Name\.c_str()), \&findFileData)/FindFirstFileW(utf16Name.c_str(), \&findFileData)/' \
            -e 's/while (FindNextFile(find\.get(), \&findFileData));/while (FindNextFileW(find.get(), \&findFileData));/' \
            -e 's/if (!CreateDirectory(utf16Name\.c_str(), nullptr))/if (!CreateDirectoryW(utf16Name.c_str(), nullptr))/' \
        src/msix/PAL/FileSystem/Win32/DirectoryObject.cpp

        # Windows-specific compiler flags
        export LDFLAGS="-L${libdir}"
        export CXXFLAGS="$CXXFLAGS -include windows.h"

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
        -DOPENSSL_INCLUDE_DIR="${prefix}" \
        -DOPENSSL_CRYPTO_LIBRARY=${libdir}/libcrypto.${dlext} \
        -DOPENSSL_SSL_LIBRARY=${libdir}/libssl.${dlext} \
        ${PLATFORM_OPTIONS} \
        .
    
    # Build only what we need
    make -j${nproc} -C build/src

    # Install license and binary
    install_license LICENSE 
    install -Dvm 755 "build/bin/makemsix${exeext}" "${bindir}/makemsix${exeext}"

    # Shared library installation
    if [[ "${target}" == *"-mingw32" ]]; then
        install -Dvm 755 "build/bin/libmsix.${dlext}" "${libdir}/libmsix.${dlext}"
    else
        install -Dvm 755 "build/lib/libmsix.${dlext}" "${libdir}/libmsix.${dlext}"
    fi
"""

platforms = supported_platforms()
filter!(p -> !(Sys.islinux(p) && arch(p) == "armv6l" && libc(p) == "musl"), platforms) # fts not available
filter!(p -> !(Sys.islinux(p) && arch(p) == "riscv64"), platforms) # Zlib and Xerces not available
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms) # Zlib and Xerces not available
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("makemsix", :makemsix),
    LibraryProduct("libmsix", :libmsix),
]

dependencies = [
    Dependency("fts_jll", compat="1.2.7", platforms=filter(p -> libc(p) == "musl", platforms)),
    Dependency("Zlib_jll", compat="1.2.13"),
    Dependency("Xerces_jll", compat="3.2.4"),
    Dependency("OpenSSL_jll", compat="3.0.16"),
    HostBuildDependency(PackageSpec(; name="CMake_jll", version=v"3.31.6")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"11")
