using BinaryBuilder, Pkg

function prepare_openfhe_build(name::String, git_hash::String)
    # Collection of sources required to complete build
    sources = [
        GitSource("https://github.com/openfheorg/openfhe-development.git",
                  git_hash),
        DirectorySource("../OpenFHE/bundled")
    ]

    # Set native size for bash recipe
    native_size = (name == "OpenFHE_128" ? 128 : 64)

    # Bash recipe for building across all platforms
    script = raw"""
    cd $WORKSPACE/srcdir/openfhe-development/

    # Set proper install directories for libraries on Windows
    if [[ "${target}" == *-mingw* ]]; then
      atomic_patch -p1 "${WORKSPACE}/srcdir/patches/windows-fix-cmake-libdir.patch"
    fi

    mkdir build && cd build

    cmake .. \
      -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DWITH_BE2=ON \
      -DWITH_BE4=ON \
      -DBUILD_UNITTESTS=OFF \
      -DBUILD_BENCHMARKS=OFF \
      -DNATIVE_SIZE=""" * "$native_size" *
    raw"""
    
    make -j${nproc}
    make install
    """
    
    # These are the platforms we will build for by default, unless further
    # platforms are passed in on the command line
    platforms = supported_platforms()

    # We cannot build with musl since OpenFHE requires the `execinfo.h` header for `backtrace`
    platforms = filter(p -> libc(p) != "musl", platforms)

    # PowerPC and 32-bit x86 platforms are not supported by OpenFHE
    platforms = filter(p -> arch(p) != "i686", platforms)
    platforms = filter(p -> arch(p) != "powerpc64le", platforms)

    # Expand C++ string ABIs since we use std::string
    platforms = expand_cxxstring_abis(platforms)

    # armv6l and armv7l do not support 128 bit int size
    if name == "OpenFHE_128"
        platforms = filter(p -> arch(p) != "armv6l", platforms)
        platforms = filter(p -> arch(p) != "armv7l", platforms)
    end

    # The products that we will ensure are always built
    products = [
        LibraryProduct("libOPENFHEbinfhe", :libOPENFHEbinfhe),
        LibraryProduct("libOPENFHEpke", :libOPENFHEpke),
        LibraryProduct("libOPENFHEcore", :libOPENFHEcore),
    ]

    # Dependencies that must be installed before this package can be built
    dependencies = Dependency[
        # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
        # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
        Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
                   platforms=filter(!Sys.isbsd, platforms)),
        Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
                   platforms=filter(Sys.isbsd, platforms)),
    ]

    return sources, script, platforms, products, dependencies
end