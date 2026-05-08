# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os, tags

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "NEO_LTS"
version = v"25.18.33578" #.42

# Aurora dgpu LTS variant of NEO (intel/compute-runtime) — currently pinned to
# LTS 2523.40 (Aurora-shipped tag 25.18.33578.42, build .42).
#
# Per-package pins for the current point release are listed at:
#   https://dgpu-docs.osgc.infra-host.com/releases/packages.html?release=LTS+2523.40&os=all
# The dependency `=`-compats below come from the Ubuntu 22.04 .deb names in
# that LTS payload (`platforms` block):
#   curl -sL https://dgpu-docs.osgc.infra-host.com/_static/packages.json \
#     | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin)['LTS 2523.40']['platforms']['Ubuntu 22.04'], indent=2))"
# Cross-checked against the in-tree NEO `manifests/manifest.yml` at this commit.
#
# Note that this build links against IGC 2.11.29 / LLVM 15 (via libigc_LTS_jll),
# while the latest NEO recipe at N/NEO/ tracks newer IGC + LLVM 16. When Aurora
# ticks a new point release, refresh the source SHA and the `=`-compats below —
# bump in place.

# Collection of sources required to build this package.
sources = [
    GitSource("https://github.com/intel/compute-runtime.git",
              "9fe190adbbaf1765e83a8cb94e406c9266b80b25"), # tag 25.18.33578.42
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

        # NOTE vs. rolling N/NEO recipe: the cxx03-revert (commit 18c25e5a) is
        # NOT applied here — that commit is not reachable from the LTS branch
        # (LTS forked before it landed), so there is nothing to revert. The
        # `mutable_indirect_data.cpp` cinttypes sed is also dropped: that file
        # does not exist in NEO 25.18.

        # work around compilation failures
        ## already defined in gmmlib
        sed -i '/__stdcall/d' shared/source/gmm_helper/gmm_lib.h
        ## extend LD_LIBRARY_PATH, don't overwrite it
        find . \( -name CMakeLists.txt -or -name '*.cmake' \) -exec \
            sed -i 's/LD_LIBRARY_PATH=/LD_LIBRARY_PATH=$ENV{LD_LIBRARY_PATH}:/g' '{}' \;
        ## NO
        sed -i '/-Werror/d' CMakeLists.txt

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
        # NEO_OCL_VERSION_MAJOR.MINOR.NEO_OCLOC_VERSION_MODE — for NEO 25.18 with default mode=1
        ln -s ocloc-25.18.1 ${bindir}/ocloc

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

# Dependencies that must be installed before this package can be built.
# Pins come from LTS 2523.40 dgpu-docs `platforms` payload (Ubuntu 22.04
# .deb versions); NEO upstream `manifest.yml` lists `intel-gmmlib-22.7.0` as
# its floor but Aurora ships `libigdgmm12_22.7.2` so we follow Aurora.
dependencies = [
    Dependency("gmmlib_jll"; compat="=22.7.2"),
    Dependency("libigc_LTS_jll"; compat="=2.11.29"),
    Dependency("oneAPI_Level_Zero_Headers_LTS_jll"; compat="=1.13.0"),
]

augment_platform_block = raw"""
    using Base.BinaryPlatforms

    # Can't use Preferences since we might be running this very early with a non-existing Manifest
    # Fresh UUID for NEO_LTS_jll. Generated locally so augment_platform_block
    # works on the very first build (Registrator will adopt this UUID at first
    # registration). DO NOT reuse NEO_jll's UUID — it would make the two JLLs
    # share the `debug` Preference.
    NEO_LTS_jll_uuid = Base.UUID("a8ea58ee-632d-4cdf-875f-a5b5188cc318")
    const preferences = Base.get_preferences(NEO_LTS_jll_uuid)
    Base.record_compiletime_preference(NEO_LTS_jll_uuid, "debug")
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
