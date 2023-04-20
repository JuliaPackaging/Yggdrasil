# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os, tags

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "NEO"
version = v"22.53.25593"#.11

# Collection of sources required to build this package.
sources = [
    GitSource("https://github.com/intel/compute-runtime.git",
              "4adb15f14975b10138939acbe17e05f2f010fc36"),
]

# Bash recipe for building across all platforms
function get_script(; debug::Bool)
    raw"""
        cd compute-runtime
        install_license LICENSE.md

        # work around compilation failures
        ## already defined in gmmlib
        sed -i '/__stdcall/d' shared/source/gmm_helper/gmm_lib.h
        ## extend LD_LIBRARY_PATH, don't overwrite it
        find . \( -name CMakeLists.txt -or -name '*.cmake' \) -exec \
            sed -i 's/LD_LIBRARY_PATH=/LD_LIBRARY_PATH=$ENV{LD_LIBRARY_PATH}:/g' '{}' \;
        ## NO
        sed -i '/-Werror/d' CMakeLists.txt

        CMAKE_FLAGS=()

        # Release build for best performance
        CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=""" * (debug ? "Debug" : "Release") * raw""")

        # Install things into $prefix
        CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

        # NOTE: NEO currently can't cross compile because of its IGC dependency
        CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=OFF)

        # Explicitly use our cmake toolchain file
        CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})

        # Don't run tests
        CMAKE_FLAGS+=(-DSKIP_UNIT_TESTS:Bool=true)

        # we don't care about cl_intel_va_api_media_sharing
        CMAKE_FLAGS+=(-DDISABLE_LIBVA:Bool=true)

        # enable support for the DG1
        CMAKE_FLAGS+=(-DSUPPORT_DG1:Bool=true)

        # libigc installs libraries and pkgconfig rules in lib64, so look for them there.
        # FIXME: shouldn't BinaryBuilder do this?
        export PKG_CONFIG_PATH=${prefix}/lib64/pkgconfig:${prefix}/lib/pkgconfig

        cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
        ninja -C build -j ${nproc} install"""
end

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    # NEO is 64-bit only: https://github.com/intel/compute-runtime/issues/179
    # and does not support musl: https://github.com/intel/compute-runtime/issues/265
    Platform("x86_64", "linux", libc="glibc"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("ocloc", :ocloc),
    LibraryProduct("libigdrcl", :libigdrcl, ["lib/intel-opencl", "lib64/intel-opencl"]),
    LibraryProduct("libze_intel_gpu", :libze_intel_gpu),
]

# Dependencies that must be installed before this package can be built
# NOTE: these hashes are taken from the release notes in GitHub,
#       https://github.com/intel/compute-runtime/releases.
#       when using a non-public release, refer to the compiled manifest
#       https://github.com/intel/compute-runtime/blob/master/manifests/manifest.yml.
dependencies = [
    Dependency("gmmlib_jll"; compat="=22.3.0"),
    Dependency("libigc_jll"; compat="=1.0.13230"),
    Dependency("oneAPI_Level_Zero_Headers_jll", v"1.5.8"; compat="1.5.8"),
]

augment_platform_block = raw"""
    using Base.BinaryPlatforms

    # Can't use Preferences since we might be running this very early with a non-existing Manifest
    NEO_jll_uuid = Base.UUID("700fe977-ac61-5f37-bbc8-c6c4b2b6a9fd")
    const preferences = Base.get_preferences(NEO_jll_uuid)
    Base.record_compiletime_preference(NEO_jll_uuid, "debug")

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

    # GCC 4 has constexpr incompatibilities
    # GCC 7 triggers: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=79929
    build_tarballs(ARGS, name, version, sources, get_script(; debug), [augmented_platform],
                   products, dependencies; preferred_gcc_version=v"8", augment_platform_block)
end
