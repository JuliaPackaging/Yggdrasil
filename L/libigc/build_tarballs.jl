# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os, tags

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "libigc"
version = v"2.18.5"

# IGC depends on LLVM, a custom Clang, and a Khronos tool. Instead of building these pieces
# separately, taking care to match versions and apply Intel-specific patches where needed
# (i.e. we can't re-use Julia's LLVM_jll) collect everything here and perform a monolithic,
# in-tree build with known-good versions.

# Collection of sources required to build IGC
# NOTE: these hashes are taken from the release notes in GitHub,
#       https://github.com/intel/intel-graphics-compiler/releases.
#
#       however, it seems like their Ubuntu build instrictions,
#       as well as the CI build infrastructure, uses way newer
#       sources, directly checking out upstream branches
#       see https://github.com/intel/intel-graphics-compiler/blob/master/documentation/build_ubuntu.md
#
#       only the SPIRV-Tools and SPIRV-Headers versions are hard-coded,
#       see https://github.com/intel/intel-graphics-compiler/blob/master/.github/workflows/build-IGC.yml
#
sources = [
    GitSource("https://github.com/intel/intel-graphics-compiler.git", "bd67908e0b06013e83ee02c9f3ff10cf976ed96a"),
    GitSource("https://github.com/intel/opencl-clang.git", "7eef46576eca117685ae431735c2725ddb889260" #= branch ocl-open-150 =#),
    GitSource("https://github.com/KhronosGroup/SPIRV-LLVM-Translator.git", "a077a090060f953ba7dd024208980ca837233d87" #= branch llvm_release_150 =#),
    GitSource("https://github.com/KhronosGroup/SPIRV-Tools.git", "28a883ba4c67f58a9540fb0651c647bb02883622" #= tag v2025.1.rc1 =#),
    GitSource("https://github.com/KhronosGroup/SPIRV-Headers.git", "04b76709bf40a7ce8df3382060ef3620f19de566"), #= main =#
    GitSource("https://github.com/intel/vc-intrinsics.git", "46286b96fb9eee9fa4fcf8b8ecf74a8c01af4c1a" #= tag v0.23.1 =#),
    GitSource("https://github.com/llvm/llvm-project.git", "8dfdcc7b7bf66834a761bd8de445840ef68e4d1a" #= tag llvmorg-15.0.7 =#),
    # patches
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
function get_script(; debug::Bool)
    script = raw"""
        apk add py3-mako py3-yaml binutils
        # Need newer CMake (>3.22.1), so use the JLL packaged one
        apk del cmake

        # Build the IGC

        # the build system uses git
        export HOME=$(pwd)
        git config --global user.name "Binary Builder"
        git config --global user.email "your@email.com"

        # move everything in places where it will get detected by the IGC build system
        mv opencl-clang llvm-project/llvm/projects/opencl-clang
        mv SPIRV-LLVM-Translator llvm-project/llvm/projects/llvm-spirv

        # Work around compilation failures
        # https://gcc.gnu.org/bugzilla/show_bug.cgi?id=86678
        atomic_patch -p0 patches/gcc-constexpr_assert_bug.patch
        # Fix iterator ambiguity with C++20 and LLVM 15
        atomic_patch -p0 patches/fix-iterator-ambiguity.patch
        # https://reviews.llvm.org/D64388
        sed -i '/add_subdirectory/i add_definitions(-D__STDC_FORMAT_MACROS)' intel-graphics-compiler/external/llvm/llvm.cmake

        # Avoid "No space left on device"
        mkdir -p tmpdir
        export TMPDIR=$(pwd)/tmpdir
        export CCACHE_TEMPDIR=$(pwd)/tmpdir

        cd intel-graphics-compiler
        install_license LICENSE.md

        CMAKE_FLAGS=()

        # Select a build type
        CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=""" * (debug ? "Debug" : "Release") * raw""")

        # Install things into $prefix
        CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

        # NOTE: igc currently can't cross compile due to a variety of issues:
        # - https://github.com/intel/intel-graphics-compiler/issues/131
        # - https://github.com/intel/opencl-clang/issues/91
        CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=OFF)

        # Explicitly use our cmake toolchain file
        CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})

        # Silence developer warnings
        CMAKE_FLAGS+=(-Wno-dev)

        cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
        ninja -C build -j ${nproc} install

        # IGC's build system is stupid and always generates debug symbols,
        # assuming you run `strip` afterwards
        if """ * (debug ? "false" : "true") * raw"""; then
            find ${libdir} ${bindir} -type f -exec strip -s {} \;
        else
            # to reduce the JLL size, always remove debug symbols of uninteresting files
            strip -s ${libdir}/libigdfcl.so*
            strip -s ${libdir}/libopencl-clang.so*
            strip -s ${bindir}/lld
        fi
        """
end

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux", libc="glibc"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct(["iga32", "iga64"], :iga),
    LibraryProduct(["libiga32", "libiga64"], :libiga),
    LibraryProduct("libigc", :libigc),
    # OpenCL support
    # XXX: put this in a separate JLL once we have JuliaPackaging/BinaryBuilder.jl#778
    #      (can't remove OpenCL support as it's used during build of NEO_jll)
    LibraryProduct("libigdfcl", :libigdfcl),
    LibraryProduct("libopencl-clang", :libopencl_clang),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("CMake_jll"),
]

augment_platform_block = raw"""
    using Base.BinaryPlatforms

    # Can't use Preferences since we might be running this very early with a non-existing Manifest
    libigc_jll_uuid = Base.UUID("94295238-5935-5bd7-bb0f-b00942e9bdd5")
    const preferences = Base.get_preferences(libigc_jll_uuid)
    Base.record_compiletime_preference(libigc_jll_uuid, "debug")
    const debug_preference = if haskey(preferences, "debug")
        if isa(preferences["debug"], Bool)
            preferences["debug"]
        elseif isa(preferences["debug"], String)
            parsed = tryparse(Bool, preferences["debug"])
            if parsed === nothing
                @error "Debug preference is not valid; expected a boolean, but got '$(preferences["debug"])'"
                nothing
            else
                parsed
            end
        else
            @error "Debug preference is not valid; expected a boolean, but got '$(preferences["debug"])'"
            nothing
        end
    else
        nothing
    end

    function augment_platform!(platform::Platform)
        platform["debug"] = string(something(debug_preference, false))
        return platform
    end"""

for platform in platforms, debug in (false, true)
    # XXX: make this more convenient in Base
    tag_kwargs = Dict(Symbol(key) => value for (key, value) in tags(platform))
    tag_kwargs[:debug] = string(debug)
    delete!(tag_kwargs, :os)
    delete!(tag_kwargs, :arch)
    augmented_platform = Platform(arch(platform), os(platform); tag_kwargs...)
    should_build_platform(triplet(augmented_platform)) || continue

    # IGC only supports Ubuntu 18.04+, which uses GCC 7.4.
    # GCC <9 triggers: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=86678 (for debug)
    build_tarballs(ARGS, name, version, sources, get_script(; debug), [augmented_platform],
                   products, dependencies; preferred_gcc_version=v"11", augment_platform_block,
                   julia_compat = "1.6", lock_microarchitecture=false)
end
