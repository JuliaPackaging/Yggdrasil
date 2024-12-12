using BinaryBuilder, Pkg

include("../../L/libjulia/common.jl")

function prepare_openfhe_julia_build(name::String, git_hash::String)
    # See https://github.com/JuliaLang/Pkg.jl/issues/2942
    # Once this Pkg issue is resolved, this must be removed
    uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
    delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

    # Collection of sources required to complete build
    sources = [
        GitSource("https://github.com/hpsc-lab/openfhe-julia.git",
                  git_hash),
    ]

    # Bash recipe for building across all platforms
    script = raw"""
    cd $WORKSPACE/srcdir/openfhe-julia/

    if [[ "${target}" == *-mingw* ]]; then
        # This is needed because otherwise we get unusable binaries (error "The specified
        # executable is not a valid application for this OS platform"). These come from
        # CompilerSupportLibraries_jll.
        # xref: https://github.com/JuliaPackaging/Yggdrasil/issues/7904
        #
        # The remove path pattern matches `lib/gcc/<triple>/<major>/`, where `<triple>` is the
        # platform triplet and `<major>` is the GCC major version with which CSL was built
        # xref: https://github.com/JuliaPackaging/Yggdrasil/pull/7535
        #
        # However, before CSL v1.1, these files were located in just `lib/`, thus we clean this
        # directory as well.
        if test -n "$(find $prefix/lib/gcc/*mingw*/*/libgcc*)"; then
            rm $prefix/lib/gcc/*mingw*/*/libgcc* $prefix/lib/gcc/*mingw*/*/libmsvcrt*
        elif test -n "$(find $prefix/lib/libgcc*)"; then
            rm $prefix/lib/libgcc* $prefix/lib/libmsvcrt*
        else
            echo "Could not find any libraries to remove :-/"
            find $prefix/lib
        fi
    fi

    CMAKE_CXX_FLAGS=""
    # For clang on macOS additional flag is required to link typeinfo(unsigned __int128)
    if [[ "$target" == *-apple-darwin* ]]; then
        CMAKE_CXX_FLAGS="-lc++abi"
    fi

    mkdir build && cd build

    cmake .. \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DJulia_PREFIX=$prefix \
    -DCMAKE_CXX_FLAGS=$CMAKE_CXX_FLAGS

    make -j${nproc}
    make install
    """

    # These are the platforms we will build for by default, unless further
    # platforms are passed in on the command line
    platforms = vcat(libjulia_platforms.(julia_versions)...)

    # We cannot build with musl since OpenFHE requires the `execinfo.h` header for `backtrace`
    platforms = filter(p -> libc(p) != "musl", platforms)

    # PowerPC and 32-bit x86 and 64-bit FreeBSD on ARM 64 platforms are not supported by OpenFHE
    platforms = filter(p -> arch(p) != "i686", platforms)
    platforms = filter(p -> arch(p) != "powerpc64le", platforms)
    platforms = filter(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)

    if name == "openfhe_julia_int128"
        # 32 bit systems does not support __int128
        platforms = filter(p -> nbits(p) != 32, platforms)
        # armv6l and armv7l do not support 128 bit int size
        platforms = filter(p -> arch(p) != "armv6l", platforms)
        platforms = filter(p -> arch(p) != "armv7l", platforms)
    end

    # Expand C++ string ABIs since we use std::string
    platforms = expand_cxxstring_abis(platforms)


    # The products that we will ensure are always built
    products = [
        LibraryProduct("libopenfhe_julia", :libopenfhe_julia),
    ]

    # Dependencies that must be installed before this package can be built
    dependencies = [
        BuildDependency(PackageSpec(;name="libjulia_jll", version=v"1.10.9")),
        Dependency(PackageSpec(name="libcxxwrap_julia_jll", uuid="3eaa8342-bff7-56a5-9981-c04077f7cee7"); compat="0.13.0"),
        # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
        # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
        Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
                platforms=filter(!Sys.isbsd, platforms)),
        Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
                platforms=filter(Sys.isbsd, platforms)),
    ]

    return sources, script, platforms, products, dependencies
end
