
# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "llvm.jl"))

name = "faust"
version = v"2.40.10"

# Collection of sources required to build faust
sources = [
    GitSource("https://github.com/grame-cncm/faust.git",
              "04bc38cd56ba5f5b10af1c86d0534364f0d5cf62"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/faust

CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DINCLUDE_HTTP=OFF)
CMAKE_FLAGS+=(-DINCLUDE_ITP=OFF)
CMAKE_FLAGS+=(-DINCLUDE_OSC=OFF)
CMAKE_FLAGS+=(-DINCLUDE_STATIC=OFF)
CMAKE_FLAGS+=(-DITPDYNAMIC=OFF)

CMAKE_TARGET=${target}

if [[ "${target}" == *musl* ]]; then
    export CXXFLAGS="-DALPINE"
fi

if [[ "${target}" == *apple* ]]; then
    export MACOSX_DEPLOYMENT_TARGET=10.9
    export LDFLAGS="${LDFLAGS} -mmacosx-version-min=10.9"
    # If we're building for Apple, CMake gets confused with `aarch64-apple-darwin` and instead prefers
    # `arm64-apple-darwin`.  If this issue persists, we may have to change our triplet printing.
    if [[ "${target}" == aarch64* ]]; then
        CMAKE_TARGET=arm64-${target#*-}
    fi
fi

if [[ "${target}" == *mingw* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/ws2.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/ws2_libraries.patch
fi

if [[ "${target}" == *freebsd* ]]; then
    export LDFLAGS="${LDFLAGS} -lexecinfo"
fi

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/unset_llvm_libs.patch


if [[ "${bb_full_target}" == x86_64-linux-musl-* ]]; then
    llvm_lib=$(basename /workspace/destdir/lib/libLLVM-??jl.so)
    LLVM_LIB="-l${llvm_lib:3:9}"
elif [[ "${bb_full_target}" == *mingw*+13 ]]; then
    LLVM_LIB="-lLLVM-13jl.dll"
elif [[ "${target}" == *mingw* ]]; then
    LLVM_LIB="-lLLVM.dll"
else
    LLVM_LIB="-lLLVM"
fi

LLVM_LIBS="${LLVM_LIB} -lstdc++"

CMAKE_FLAGS+=(-DLLVM_LIBS=\'${LLVM_LIBS}\')

CMAKE_FLAGS+=(-DCMAKE_C_COMPILER_TARGET=${CMAKE_TARGET})
CMAKE_FLAGS+=(-DCMAKE_CXX_COMPILER_TARGET=${CMAKE_TARGET})

CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

CMAKE_FLAGS+=(-DUSE_LLVM_CONFIG=OFF)
CMAKE_FLAGS+=(-DLLVM_DIR=${prefix}/lib/cmake/llvm)

export CMAKEOPT="${CMAKE_FLAGS[@]}"
export PREFIX=$prefix

make -j${nproc} all
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    ExecutableProduct("faust", :faust),
    LibraryProduct("libfaust", :libfaust),
    LibraryProduct("libHTTPDFaust", :libHTTPDFaust),
    LibraryProduct("libOSCFaust", :libOSCFaust),

    # Generated list of Faust scripts using:
    # find $prefix/bin -maxdepth 1 -name 'faust2*' -printf '    FileProduct(joinpath("bin", "%f"), :%f),\n' | sort
    FileProduct(joinpath("bin", "faust2alqt"), :faust2alqt),
    FileProduct(joinpath("bin", "faust2alsaconsole"), :faust2alsaconsole),
    FileProduct(joinpath("bin", "faust2alsa"), :faust2alsa),
    FileProduct(joinpath("bin", "faust2android"), :faust2android),
    FileProduct(joinpath("bin", "faust2androidunity"), :faust2androidunity),
    FileProduct(joinpath("bin", "faust2api"), :faust2api),
    FileProduct(joinpath("bin", "faust2atomsnippets"), :faust2atomsnippets),
    FileProduct(joinpath("bin", "faust2au"), :faust2au),
    FileProduct(joinpath("bin", "faust2bela"), :faust2bela),
    FileProduct(joinpath("bin", "faust2caqt"), :faust2caqt),
    FileProduct(joinpath("bin", "faust2caqtios"), :faust2caqtios),
    FileProduct(joinpath("bin", "faust2csound"), :faust2csound),
    FileProduct(joinpath("bin", "faust2csvplot"), :faust2csvplot),
    FileProduct(joinpath("bin", "faust2dplug"), :faust2dplug),
    FileProduct(joinpath("bin", "faust2dssi"), :faust2dssi),
    FileProduct(joinpath("bin", "faust2dummy"), :faust2dummy),
    FileProduct(joinpath("bin", "faust2dummymem"), :faust2dummymem),
    FileProduct(joinpath("bin", "faust2eps"), :faust2eps),
    FileProduct(joinpath("bin", "faust2esp32"), :faust2esp32),
    FileProduct(joinpath("bin", "faust2faustvst"), :faust2faustvst),
    FileProduct(joinpath("bin", "faust2firefox"), :faust2firefox),
    FileProduct(joinpath("bin", "faust2gen"), :faust2gen),
    FileProduct(joinpath("bin", "faust2graph"), :faust2graph),
    FileProduct(joinpath("bin", "faust2graphviewer"), :faust2graphviewer),
    FileProduct(joinpath("bin", "faust2ios"), :faust2ios),
    FileProduct(joinpath("bin", "faust2jackconsole"), :faust2jackconsole),
    FileProduct(joinpath("bin", "faust2jack"), :faust2jack),
    FileProduct(joinpath("bin", "faust2jackrust"), :faust2jackrust),
    FileProduct(joinpath("bin", "faust2jackserver"), :faust2jackserver),
    FileProduct(joinpath("bin", "faust2jaqtchain"), :faust2jaqtchain),
    FileProduct(joinpath("bin", "faust2jaqt"), :faust2jaqt),
    FileProduct(joinpath("bin", "faust2juce"), :faust2juce),
    FileProduct(joinpath("bin", "faust2ladspa"), :faust2ladspa),
    FileProduct(joinpath("bin", "faust2linuxunity"), :faust2linuxunity),
    FileProduct(joinpath("bin", "faust2lv2"), :faust2lv2),
    FileProduct(joinpath("bin", "faust2mathdoc"), :faust2mathdoc),
    FileProduct(joinpath("bin", "faust2mathviewer"), :faust2mathviewer),
    FileProduct(joinpath("bin", "faust2max6"), :faust2max6),
    FileProduct(joinpath("bin", "faust2md"), :faust2md),
    FileProduct(joinpath("bin", "faust2msp"), :faust2msp),
    FileProduct(joinpath("bin", "faust2netjackconsole"), :faust2netjackconsole),
    FileProduct(joinpath("bin", "faust2netjackqt"), :faust2netjackqt),
    FileProduct(joinpath("bin", "faust2nodejs"), :faust2nodejs),
    FileProduct(joinpath("bin", "faust2octave"), :faust2octave),
    FileProduct(joinpath("bin", "faust2osxiosunity"), :faust2osxiosunity),
    FileProduct(joinpath("bin", "faust2owl"), :faust2owl),
    FileProduct(joinpath("bin", "faust2paqt"), :faust2paqt),
    FileProduct(joinpath("bin", "faust2pdf"), :faust2pdf),
    FileProduct(joinpath("bin", "faust2plot"), :faust2plot),
    FileProduct(joinpath("bin", "faust2png"), :faust2png),
    FileProduct(joinpath("bin", "faust2portaudiorust"), :faust2portaudiorust),
    FileProduct(joinpath("bin", "faust2puredata"), :faust2puredata),
    FileProduct(joinpath("bin", "faust2pure"), :faust2pure),
    FileProduct(joinpath("bin", "faust2raqt"), :faust2raqt),
    FileProduct(joinpath("bin", "faust2ros"), :faust2ros),
    FileProduct(joinpath("bin", "faust2rosgtk"), :faust2rosgtk),
    FileProduct(joinpath("bin", "faust2rpialsaconsole"), :faust2rpialsaconsole),
    FileProduct(joinpath("bin", "faust2rpinetjackconsole"), :faust2rpinetjackconsole),
    FileProduct(joinpath("bin", "faust2sam"), :faust2sam),
    FileProduct(joinpath("bin", "faust2sc"), :faust2sc),
    FileProduct(joinpath("bin", "faust2sig"), :faust2sig),
    FileProduct(joinpath("bin", "faust2sigviewer"), :faust2sigviewer),
    FileProduct(joinpath("bin", "faust2smartkeyb"), :faust2smartkeyb),
    FileProduct(joinpath("bin", "faust2sndfile"), :faust2sndfile),
    FileProduct(joinpath("bin", "faust2soul"), :faust2soul),
    FileProduct(joinpath("bin", "faust2supercollider"), :faust2supercollider),
    FileProduct(joinpath("bin", "faust2svg"), :faust2svg),
    FileProduct(joinpath("bin", "faust2svgviewer"), :faust2svgviewer),
    FileProduct(joinpath("bin", "faust2teensy"), :faust2teensy),
    FileProduct(joinpath("bin", "faust2unity"), :faust2unity),
    FileProduct(joinpath("bin", "faust2vcvrack"), :faust2vcvrack),
    FileProduct(joinpath("bin", "faust2vst"), :faust2vst),
    FileProduct(joinpath("bin", "faust2vsti"), :faust2vsti),
    FileProduct(joinpath("bin", "faust2w32max6"), :faust2w32max6),
    FileProduct(joinpath("bin", "faust2w32msp"), :faust2w32msp),
    FileProduct(joinpath("bin", "faust2w32puredata"), :faust2w32puredata),
    FileProduct(joinpath("bin", "faust2w32vst"), :faust2w32vst),
    FileProduct(joinpath("bin", "faust2w64max6"), :faust2w64max6),
    FileProduct(joinpath("bin", "faust2w64vst"), :faust2w64vst),
    FileProduct(joinpath("bin", "faust2wasm"), :faust2wasm),
    FileProduct(joinpath("bin", "faust2webaudiowasm"), :faust2webaudiowasm),
    FileProduct(joinpath("bin", "faust2webaudiowast"), :faust2webaudiowast),
    FileProduct(joinpath("bin", "faust2winunity"), :faust2winunity), 

    FileProduct(joinpath("bin","faustoptflags"), :faustoptflags),
    FileProduct(joinpath("bin","usage.sh"), :usage_sh),

    FileProduct(joinpath("share", "faust", "stdfaust.lib"), :stdfaust_lib),
]

llvm_versions = [v"11.0.1", v"12.0.1", v"13.0.1"]

sources = Dict(
    v"11.0.1" => [sources; ],
    v"12.0.1" => [sources; ],
    v"13.0.1" => [sources; ],
)

base_dependencies = [
    Dependency("libmicrohttpd_jll"),
    Dependency("libsndfile_jll"),
    BuildDependency("Ncurses_jll"),
    BuildDependency("XML2_jll"),
    BuildDependency("Zlib_jll"),
]

augment_platform_block = """
    using Base.BinaryPlatforms
    $(LLVM.augment)
    function augment_platform!(platform::Platform)
        augment_llvm!(platform)
    end
"""

# determine exactly which tarballs we should build
builds = []
for llvm_version in llvm_versions
    # Dependencies that must be installed before this package can be built
    llvm_name = "LLVM_full_jll"
    dependencies = [
	base_dependencies;
        BuildDependency(PackageSpec(name=llvm_name, version=llvm_version))
    ]

    for platform in platforms
        augmented_platform = deepcopy(platform)
        augmented_platform[LLVM.platform_name] = LLVM.platform(llvm_version, false)

        should_build_platform(triplet(augmented_platform)) || continue
        push!(builds, (;
            dependencies,
            sources=sources[llvm_version],
            platforms=[augmented_platform],
        ))
    end
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, script,
                   build.platforms, products, build.dependencies;
                   preferred_gcc_version=v"8", julia_compat="1.6",
                   augment_platform_block, lazy_artifacts=true)
end
