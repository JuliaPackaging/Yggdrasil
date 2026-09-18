# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Chris Johnson's Airwindows effects -- 504 of them -- as a single CLAP module.
#
# Two sources, and the split between them is the point. The DSP comes from
# baconpaul/airwin2rack, which consolidates Airwindows into one static library,
# `airwin-registry`. The adapter from that registry to CLAP is one translation
# unit, `csrc/airwindows/airwindows_clap.cpp`, in AudioPlugins.jl -- the same
# repository whose `csrc/` already builds into CLAPHost_jll, LV2Host_jll and
# VST3Host_jll, built here the same way.
#
# LICENCE: MIT end to end, which is why this can ship as a JLL at all.
# airwin2rack's README says it in as many words: "all code and content in
# `src`, in `libs/airwindows` and in `res/awdoc` is freely available, under the
# MIT license, and fine to use in closed source code. This means you can just
# link the `airwin-registry` cmake target". Which is exactly and only what this
# recipe does. The GPL3 exposure that README warns about comes from building
# its *front ends* -- `src-juce` against JUCE and the VST3 SDK, `src-rack`
# against the VCV Rack SDK -- and both are behind CMake options that default
# OFF (`BUILD_JUCE_PLUGIN`, `BUILD_RACK_PLUGIN`) and are explicitly forced OFF
# below. No JUCE, VST3 SDK or Rack SDK source is fetched, compiled or linked;
# the only two submodules in the tree are not fetched either. CLAP itself is
# header-only MIT, vendored in AudioPlugins.jl.
#
# The one wrinkle: `airwin-registry` links `awdoc_resources`, a CMakeRC blob of
# `res/awpdoc/*.txt` (532 files of Chris Johnson's per-effect documentation),
# so that prose is baked into the artifact. That is the directory the README's
# licence note calls `res/awdoc` -- no `res/awdoc` exists in the tree, `awpdoc`
# is the only documentation directory, so the note plainly refers to it.
#
# VERSIONING: unlike CLAPHost/LV2Host/VST3Host, whose version tracks the
# AudioPlugins.jl release whose `csrc/` they compile, almost all of this
# artifact is *upstream* DSP, so its version has to be able to move when either
# input moves. The scheme:
#   patch  -- the adapter changed, same airwin2rack commit (same 504 effects).
#   minor  -- the airwin2rack pin moved and upstream added effects. Additive:
#             ids derive from effect names, so existing ids keep pointing at
#             the same effect and only the registry count grows.
#   major  -- an id changed meaning or disappeared, i.e. upstream renamed or
#             removed an effect. Nothing else earns a major.
name = "Airwindows"
version = v"1.0.0"

sources = [
    # The adapter. `main` at the time of writing (the merge of
    # SciML/AudioPlugins.jl#30); Project.toml says 1.4.0, which is unreleased,
    # so this is a commit rather than a tag. It is reachable from both #44,
    # which added the adapter, and #48, which added the lib/Airwindows
    # sublibrary that consumes this JLL. The same commit is pinned by
    # C/CLAPHost v1.1.0, so the host and the collection it scans agree.
    GitSource("https://github.com/SciML/AudioPlugins.jl.git",
              "c423763d0d367f3119574eba102714200b4bdb13"),
    # The DSP. Pinned to a commit rather than a tag on purpose: AudioPlugins'
    # test/probe_airwindows.c and lib/Airwindows/test/runtests.jl both assert
    # the registry holds exactly 504 effects, so a moving tag would turn an
    # upstream addition into a red build somewhere else. The same commit is
    # pinned in AudioPlugins' .github/workflows/CProbe.yml; move the two
    # together, and bump the minor version here when you do.
    GitSource("https://github.com/baconpaul/airwin2rack.git",
              "2a6d1c019e1b54a0376d479edf083694369f78b1"),
]

script = raw"""
AP=${WORKSPACE}/srcdir/AudioPlugins.jl
AW=${WORKSPACE}/srcdir/airwin2rack

install_license ${AP}/LICENSE ${AP}/csrc/vendor/CLAP-LICENSE ${AW}/LICENSE.md

# The registry, and nothing else in the tree. Both front-end options default
# OFF already; they are passed explicitly so that an upstream default flip
# cannot quietly pull JUCE or the Rack SDK -- and their GPL3 -- into the build.
cd ${AW}
cmake -S . -B build \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_JUCE_PLUGIN=OFF \
    -DBUILD_RACK_PLUGIN=OFF
cmake --build build --parallel ${nproc} --target airwin-registry

# The adapter, linked against it: 1047 translation units of DSP in, one
# exported symbol out. A .clap is dlopened into a host that has its own C++
# runtime -- Julia's, here -- so the module must neither need a second copy
# nor export one into it. Hence the static runtime and the cut export list;
# -fvisibility=hidden alone is not enough, because libstdc++ marks namespace
# std explicitly visible and 18 template instantiations leak without the
# version script. This is also why no cxxstring_abi expansion is needed: the
# only ABI the artifact presents is CLAP's, which is C.
cd ${AP}
mkdir -p "${libdir}/clap"

# The version every CLAP descriptor reports, injected so it cannot drift from
# the JLL's. Written to a header and -include'd rather than passed as -D: a
# macro whose value is a quoted string does not survive the trip into this
# script, which strips the backslashes that would protect the inner quotes.
printf '#define AIRWINDOWS_VERSION "%s"\n' "${AIRWINDOWS_VERSION}" > aw_version.h

if [[ "${target}" == *-apple-* ]]; then
    printf '_clap_entry\n' > aw_exports.syms
    LINK_EXTRA="-Wl,-exported_symbols_list,aw_exports.syms"
elif [[ "${target}" == *-mingw* ]]; then
    # -static rather than just -static-libstdc++: mingw's libstdc++ threading
    # pulls libwinpthread-1.dll, and with no dependencies declared there is
    # nothing to ship it. CLAP_EXPORT is __declspec(dllexport) here, so the
    # export table is already just clap_entry and needs no help.
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

# The version the module reports through its CLAP descriptors, so that a host
# can tell which build it loaded without reading the JLL's Project.toml.
script = "AIRWINDOWS_VERSION=$(version)\n" * script

platforms = filter(p -> Sys.islinux(p) || Sys.isapple(p) || Sys.iswindows(p),
                   supported_platforms())

# A `.clap` is a shared object under a non-standard extension (a directory
# bundle on macOS, by convention -- AudioPlugins' host dlopens the plain file
# first and only then looks for Contents/MacOS, so a flat file is what is
# shipped and it works on all three). LibraryProduct would go looking for
# `libairwindows.${dlext}`, so this is a FileProduct, which is also what
# lib/Airwindows wants: it hands the path to `register_bundle!`. `libdir` is
# `bin` on Windows and `lib` everywhere else, hence the two candidates.
products = [
    FileProduct(["lib/clap/Airwindows.clap", "bin/clap/Airwindows.clap"], :airwindows_clap),
]

# None. The C++ runtime is linked statically above, so the module is
# self-contained -- which is the right shape for something a host dlopens.
dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"9")
