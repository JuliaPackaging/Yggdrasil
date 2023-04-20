# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os, tags

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "libigc"
version = v"1.0.13230"#.7

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
    GitSource("https://github.com/intel/intel-graphics-compiler.git", "0e001e2814fd4e0e56275ab45adecea8f79e9ee8"),
    GitSource("https://github.com/intel/opencl-clang.git", "10237c7109d613ef1161065d140b76d92133062f" #= branch ocl-open-110 =#),
    GitSource("https://github.com/KhronosGroup/SPIRV-LLVM-Translator.git", "4bce20785af572aec035db247225205a865a0ca6" #= branch llvm_release_110 =#),
    GitSource("https://github.com/KhronosGroup/SPIRV-Tools.git", "eb0a36633d2acf4de82588504f951ad0f2cecacb" #= tag sdk-1.3.231.1 =#),
    GitSource("https://github.com/KhronosGroup/SPIRV-Headers.git", "85a1ed200d50660786c1a88d9166e871123cce39" #= tag sdk-1.3.231.1 =#),
    GitSource("https://github.com/intel/vc-intrinsics.git", "dd72efa3b4aafdbbf599e6f3c6f8c55450e348de" #= latest version: v0.11.0 =#),
    GitSource("https://github.com/llvm/llvm-project.git", "1fdec59bffc11ae37eb51a1b9869f0696bfd5312" #= branch llvmorg-11.1.0 =#),
    # patches
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
function get_script(; debug::Bool)
    script = raw"""
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
        # https://reviews.llvm.org/D64388
        sed -i '/add_subdirectory/i add_definitions(-D__STDC_FORMAT_MACROS)' intel-graphics-compiler/external/llvm/llvm.cmake

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

        # we (currently) don't care about OpenCL support, so get rid of it
        rm -rf ${libdir}/libigdfcl.so*
        rm -rf ${libdir}/libopencl-clang.so*

        # IGC's build system is stupid and always generated debug symbols,
        # assuming you run `strip` afterwards
        if """ * (debug ? "false" : "true") * raw"""; then
            find ${libdir} ${bindir} -type f -exec strip -s {} \;
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
    ExecutableProduct("GenX_IR", :GenX_IR),
    ExecutableProduct(["iga32", "iga64"], :iga),
    LibraryProduct(["libiga32", "libiga64"], :libiga),
    LibraryProduct("libigc", :libigc),
    # OpenCL support
    #LibraryProduct("libigdfcl", :libigdfcl),
    #LibraryProduct("libopencl-clang", :libopencl_clang),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

augment_platform_block = raw"""
    using Base.BinaryPlatforms

    # Can't use Preferences since we might be running this very early with a non-existing Manifest
    libigc_jll_uuid = Base.UUID("94295238-5935-5bd7-bb0f-b00942e9bdd5")
    const preferences = Base.get_preferences(libigc_jll_uuid)
    Base.record_compiletime_preference(libigc_jll_uuid, "debug")

    function augment_platform!(platform::Platform)
        debug = tryparse(Bool, get(preferences, "debug", "false"))
        if debug === nothing
            @error "Invalid preference debug=$(get(preferences, "debug", "false"))"
        elseif !haskey(platform, "debug")
            platform["debug"] = string(debug)
        end
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
                   products, dependencies; preferred_gcc_version=v"9", augment_platform_block,
                   lock_microarchitecture=false)
end
