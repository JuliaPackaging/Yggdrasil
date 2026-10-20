# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Chris Johnson's Airwindows effects -- 504 of them -- as a single CLAP module:
# the DSP from baconpaul/airwin2rack's `airwin-registry` target, and a CLAP
# adapter from AudioPlugins.jl, whose `csrc/` also builds CLAPHost_jll,
# LV2Host_jll and VST3Host_jll.
#
# MIT end to end. airwin2rack's GPL3 exposure comes from its front ends
# (`src-juce` against JUCE and the VST3 SDK, `src-rack` against the VCV Rack
# SDK); both are behind CMake options that default OFF and are forced OFF
# below, so no GPL3 source is fetched, compiled or linked.
#
# Versioning, since most of the artifact is upstream DSP rather than adapter:
# patch = adapter only; minor = the airwin2rack pin moved and added effects
# (ids derive from effect names, so existing ids keep their meaning); major =
# an id changed meaning or disappeared.
name = "Airwindows"
version = v"1.0.0"

sources = [
    GitSource("https://github.com/SciML/AudioPlugins.jl.git",
              "c423763d0d367f3119574eba102714200b4bdb13"),
    # Pinned to a commit rather than a tag because AudioPlugins' probes assert
    # the registry holds exactly 504 effects: a moving tag would turn an
    # upstream addition into a red build elsewhere. The same commit is pinned
    # in AudioPlugins' CProbe.yml -- move both together and bump the minor.
    GitSource("https://github.com/baconpaul/airwin2rack.git",
              "2a6d1c019e1b54a0376d479edf083694369f78b1"),
]

script = raw"""
AP=${WORKSPACE}/srcdir/AudioPlugins.jl
AW=${WORKSPACE}/srcdir/airwin2rack

install_license ${AP}/LICENSE ${AP}/csrc/vendor/CLAP-LICENSE ${AW}/LICENSE.md

# The front-end options are passed explicitly, though they already default OFF,
# so an upstream default flip cannot pull JUCE or the Rack SDK into the build.
cd ${AW}
cmake -S . -B build \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_JUCE_PLUGIN=OFF \
    -DBUILD_RACK_PLUGIN=OFF
cmake --build build --parallel ${nproc} --target airwin-registry

cd ${AP}
mkdir -p "${libdir}/clap"

# Written to a header and -include'd rather than passed as -D: a macro whose
# value is a quoted string does not survive the trip into this script.
printf '#define AIRWINDOWS_VERSION "%s"\n' "${AIRWINDOWS_VERSION}" > aw_version.h

# A .clap is dlopened into a host carrying its own C++ runtime, so the module
# must neither need a second copy nor export one. -fvisibility=hidden alone is
# not enough: libstdc++ marks namespace std explicitly visible, and template
# instantiations leak without the export list. This is also why no
# cxxstring_abi expansion is needed -- the only ABI presented is CLAP's, in C.
if [[ "${target}" == *-apple-* ]]; then
    printf '_clap_entry\n' > aw_exports.syms
    LINK_EXTRA="-Wl,-exported_symbols_list,aw_exports.syms"
elif [[ "${target}" == *-mingw* ]]; then
    # -static, not just -static-libstdc++: mingw's libstdc++ threading pulls
    # libwinpthread-1.dll, and nothing would ship it.
    LINK_EXTRA="-static -Wl,--exclude-libs,ALL -Wl,--no-undefined"
else
    printf '{ global: clap_entry; local: *; };\n' > aw_exports.map
    LINK_EXTRA="-static-libstdc++ -static-libgcc -Wl,--version-script=aw_exports.map -Wl,--exclude-libs,ALL -Wl,--no-undefined"
fi

${CXX} -std=c++17 -O2 -fPIC -shared \
    -fvisibility=hidden -fvisibility-inlines-hidden \
    -include aw_version.h \
    -isystem "${AW}/src" \
    -o "${libdir}/clap/Airwindows.clap" \
    csrc/airwindows/airwindows_clap.cpp \
    -L"${AW}/build" -lairwin-registry -lawdoc_resources \
    ${LINK_EXTRA}
"""

# So a host can tell which build it loaded without reading Project.toml.
script = "AIRWINDOWS_VERSION=$(version)\n" * script

platforms = filter(p -> Sys.islinux(p) || Sys.isapple(p) || Sys.iswindows(p),
                   supported_platforms())

# A FileProduct, not a LibraryProduct: a `.clap` is a shared object under a
# non-standard extension, so the usual `lib<name>.${dlext}` search would miss
# it, and lib/Airwindows wants the path anyway to hand to `register_bundle!`.
# `libdir` is `bin` on Windows and `lib` elsewhere, hence the two candidates.
products = [
    FileProduct(["lib/clap/Airwindows.clap", "bin/clap/Airwindows.clap"], :airwindows_clap),
]

dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"9")
