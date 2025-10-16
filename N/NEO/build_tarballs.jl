# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os, tags

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "NEO"
version = v"25.35.35096"#.9

# Collection of sources required to build this package.
sources = [
    GitSource("https://github.com/intel/compute-runtime.git",
              "06099fa8b4da8281809931ebdc08c634621e3203"),
    # patches
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
function get_script(; debug::Bool)
    raw"""
        # ocloc segfaults after successful build and before exiting. So we wrap
        # a script around ocloc that detects when the build is reported
        # successful and ignores the segfault.
        atomic_patch -p0 ./patches/ocloc.patch
        # Fix OpenCL ICD installation to use prefix instead of /etc
        atomic_patch -p0 ./patches/install_to_prefix.patch
        cp ocloc_wrapper.sh compute-runtime/shared/source/built_ins/kernels/ocloc_wrapper.sh
        mkdir -p tmpdir
        export TMPDIR=$(pwd)/tmpdir
        export CCACHE_TEMPDIR=$(pwd)/tmpdir
        cd compute-runtime
        install_license LICENSE.md

        # revert a change that breaks the cxx03 build
        # https://github.com/intel/compute-runtime/issues/708
        git revert 18c25e5aa3fc00c7d47469713adeace08a9aec07

        # work around compilation failures
        ## already defined in gmmlib
        sed -i '/__stdcall/d' shared/source/gmm_helper/gmm_lib.h
        ## extend LD_LIBRARY_PATH, don't overwrite it
        find . \( -name CMakeLists.txt -or -name '*.cmake' \) -exec \
            sed -i 's/LD_LIBRARY_PATH=/LD_LIBRARY_PATH=$ENV{LD_LIBRARY_PATH}:/g' '{}' \;
        ## NO
        sed -i '/-Werror/d' CMakeLists.txt

        # Fails because C header is used in C++ code
        sed -i 's/inttypes\.h/cinttypes/g' level_zero/core/source/mutable_cmdlist/mutable_indirect_data.cpp

        CMAKE_FLAGS=()

        # Need C++20
        CMAKE_FLAGS+=(-DCMAKE_CXX_STANDARD=20)

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

        # additional hardware support
        CMAKE_FLAGS+=(-DNEO_ENABLE_i915_PRELIM_DETECTION=TRUE)

        # libigc installs libraries and pkgconfig rules in lib64, so look for them there.
        # FIXME: shouldn't BinaryBuilder do this?
        export PKG_CONFIG_PATH=${prefix}/lib64/pkgconfig:${prefix}/lib/pkgconfig

        cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
        ninja -C build -j ${nproc} install
        # Create unversioned symlinks
        ln -s ocloc-25.35.1 ${bindir}/ocloc

"""
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
    Dependency("gmmlib_jll"; compat="=22.8.1"),
    Dependency("libigc_jll"; compat="=2.18.5"),
    Dependency("oneAPI_Level_Zero_Headers_jll"; compat="=1.13"),
]

augment_platform_block = raw"""
    using Base.BinaryPlatforms

    # Can't use Preferences since we might be running this very early with a non-existing Manifest
    NEO_jll_uuid = Base.UUID("700fe977-ac61-5f37-bbc8-c6c4b2b6a9fd")
    const preferences = Base.get_preferences(NEO_jll_uuid)
    Base.record_compiletime_preference(NEO_jll_uuid, "debug")
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

    # GCC 4 has constexpr incompatibilities
    # GCC 7 triggers: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=79929
    # Needs at least GCC 10 for C++20 support of 'concepts'
    # Needs GCC 11 for std::make_unique_for_overwrite
    build_tarballs(ARGS, name, version, sources, get_script(; debug), [augmented_platform],
                   products, dependencies; preferred_gcc_version=v"11", julia_compat = "1.6",
                   augment_platform_block)
end
# bump