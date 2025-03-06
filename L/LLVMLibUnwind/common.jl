# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

function configure(version; experimental::Bool=false)
    name = "LLVMLibUnwind"

    hash = Dict(
        # libunwind-*.src.tar.xz
        v"11.0.0" => "8455011c33b14abfe57b2fd9803fb610316b16d4c9818bec552287e2ba68922f",
        v"11.0.1" => "6db3b173d872911c9ce1f2779ea4463b3b7e582b4e5fda9d3a005c1ed5ec517f",
        v"12.0.1" => "0bea6089518395ca65cf58b0a450716c5c99ce1f041079d3aa42d280ace15ca4",
        # llvm-project-*.src.tar.xz
        v"14.0.6" => "8b3cfd7bc695bd6cea0f37f53f0981f34f87496e79e2529874fd03a2f9dd3a8a",
        v"18.1.7" => "74446ab6943f686391954cbda0d77ae92e8a60c432eff437b8666e121d748ec4",
        v"19.1.4" => "3aa2d2d2c7553164ad5c6f3b932b31816e422635e18620c9349a7da95b98d811",
    )

    # LLVM deprecated standalone builds for several projects, including libunwind, so
    # for later versions we need the full LLVM source rather than just libunwind even
    # though libunwind doesn't link to libLLVM.
    source = version >= v"14" ? "llvm-project" : "libunwind"

    # Collection of sources required to complete build
    sources = [
        ArchiveSource("https://github.com/llvm/llvm-project/releases/download/llvmorg-$(version)/$(source)-$(version).src.tar.xz", hash[version]),
        DirectorySource("./bundled"; follow_symlinks=true),
    ]

    script = if version > v"14"
        raw"""
        cd ${WORKSPACE}/srcdir/llvm-project*/

        CMAKE_FLAGS=()
        CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
        CMAKE_FLAGS+=(-DCMAKE_INSTALL_INCLUDEDIR=${includedir})
        CMAKE_FLAGS+=(-DCMAKE_INSTALL_BINDIR=${libdir})
        CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=True)
        CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
        CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=MinSizeRel)  # Note: Disables debug messages
        CMAKE_FLAGS+=(-DLIBUNWIND_INCLUDE_DOCS=OFF)
        CMAKE_FLAGS+=(-DLIBUNWIND_INCLUDE_TESTS=OFF)
        CMAKE_FLAGS+=(-DLIBUNWIND_INSTALL_HEADERS=ON)
        CMAKE_FLAGS+=(-DLIBUNWIND_ENABLE_PEDANTIC=OFF)
        CMAKE_FLAGS+=(-DLIBUNWIND_ENABLE_ASSERTIONS=OFF)
        CMAKE_FLAGS+=(-DLLVM_ENABLE_RUNTIMES="libunwind")

        if [[ ${target} == x86_64-w64-mingw32 ]]; then
            # Support for threading requires Windows Vista.
            export CXXFLAGS="-D_WIN32_WINNT=0x0600"
        fi

        pushd libunwind
        # Apply all our patches
        if [ -d $WORKSPACE/srcdir/patches ]; then
            for f in $WORKSPACE/srcdir/patches/*.patch; do
                echo "Applying patch ${f}"
                atomic_patch -p2 ${f}
            done
        fi
        popd

        mkdir build
        cmake -GNinja -S runtimes -B build "${CMAKE_FLAGS[@]}" ..
        ninja -C build -j${nproc} -vv unwind
        ninja -C build install-unwind

        install_license LICENSE.TXT
        """
    elseif version == v"14"
        raw"""
        cd ${WORKSPACE}/srcdir/llvm-project*/libunwind/

        CMAKE_FLAGS=()
        CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
        CMAKE_FLAGS+=(-DCMAKE_INSTALL_INCLUDEDIR=${includedir})
        CMAKE_FLAGS+=(-DCMAKE_INSTALL_BINDIR=${libdir})
        CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=True)
        CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
        CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=MinSizeRel)  # Note: Disables debug messages
        CMAKE_FLAGS+=(-DLIBUNWIND_INCLUDE_DOCS=OFF)
        CMAKE_FLAGS+=(-DLIBUNWIND_INCLUDE_TESTS=OFF)
        CMAKE_FLAGS+=(-DLIBUNWIND_INSTALL_HEADERS=ON)
        CMAKE_FLAGS+=(-DLIBUNWIND_ENABLE_PEDANTIC=OFF)
        CMAKE_FLAGS+=(-DLIBUNWIND_ENABLE_ASSERTIONS=OFF)

        if [[ ${target} == x86_64-w64-mingw32 ]]; then
            # Support for threading requires Windows Vista.
            export CXXFLAGS="-D_WIN32_WINNT=0x0600"
        fi

        # Apply all our patches
        if [ -d $WORKSPACE/srcdir/patches ]; then
            for f in $WORKSPACE/srcdir/patches/*.patch; do
                echo "Applying patch ${f}"
                atomic_patch -p2 ${f}
            done
        fi

        mkdir build && cd build
        cmake "${CMAKE_FLAGS[@]}" ..
        make -j${nprocs}
        make install

        install_license ../LICENSE.TXT
        """
    else
        raw"""
        cd $WORKSPACE/srcdir/libunwind*

        CMAKE_FLAGS=()
        CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=$prefix)
        CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
        CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=MinSizeRel)  # Note: Disables debug messages
        CMAKE_FLAGS+=(-DLIBUNWIND_INCLUDE_DOCS=OFF)
        CMAKE_FLAGS+=(-DLIBUNWIND_ENABLE_PEDANTIC=OFF)

        if [[ ${target} == x86_64-w64-mingw32 ]]; then
            # Support for threading requires Windows Vista.
            export CXXFLAGS="-D_WIN32_WINNT=0x0600"
        fi

        # Apply all our patches
        if [ -d $WORKSPACE/srcdir/patches ]; then
            for f in $WORKSPACE/srcdir/patches/*.patch; do
                echo "Applying patch ${f}"
                atomic_patch -p2 ${f}
            done
        fi

        mkdir build && cd build
        cmake "${CMAKE_FLAGS[@]}" ..
        make -j${nprocs}
        make install

        # Install header files. Required to access patched in functions
        cp -aR ../include ${prefix}/

        # Move over the DLL. TODO: There may be a CMAKE flag for this.
        if [[ ${target} == *mingw32* ]]; then
            mkdir -p "${libdir}"
            mv -v lib/libunwind.dll "${libdir}"
        fi
        """
    end

    # These are the platforms we will build for by default, unless further
    # platforms are passed in on the command line
    platforms = supported_platforms(; experimental=experimental)

    # The products that we will ensure are always built
    products = [
        LibraryProduct("libunwind", :libunwind),
    ]

    # Dependencies that must be installed before this package can be built
    dependencies = Dependency[
    ]

    return name, version, sources, script, platforms, products, dependencies
end
