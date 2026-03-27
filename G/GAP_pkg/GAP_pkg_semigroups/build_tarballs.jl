# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

gap_version = v"400.1500.0"
name = "semigroups"
upstream_version = "5.6.1" # when you increment this, reset offset to v"0.0.0"
offset = v"1.0.0" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://github.com/semigroups/Semigroups/releases/download/v$(upstream_version)/semigroups-$(upstream_version).tar.gz",
                  "92123474c067710219f7813c0511fb418338a04e493d0d2dbfb0a88ad5c6dc9d"),
]

# Bash recipe for building across all platforms
script = raw"""
cd semigroups*

EXTRA_FLAGS=()
if [[ "${target}" == *apple-darwin* ]]; then
    # lld does support the single_module flag
    # but the detection is broken due to a warning
    # see https://savannah.gnu.org/support/?110937
    EXTRA_FLAGS+=(lt_cv_apple_cc_single_mod=yes)
fi

# not enough space in /tmp on buildkite
export TMPDIR=$WORKSPACE/tmp
mkdir $TMPDIR

if [[ "${target}" == powerpc64le* ]]; then
    # work around https://gitlab.com/libeigen/eigen/-/work_items/2259 until the fixed eigen gets used in libsemigroups (https://github.com/libsemigroups/libsemigroups/issues/932)
    export CXXFLAGS="-DEIGEN_ALTIVEC_DISABLE_MMA"
fi

./configure \
    --build=${MACHTYPE} \
    --host=${target} \
    --with-gaproot=${prefix}/lib/gap \
    --disable-hpcombi \
    --disable-backward \
    --with-external-libsemigroups \
    "${EXTRA_FLAGS[@]}"
make -j${nproc}

# copy the loadable module
mkdir -p ${prefix}/lib/gap
cp bin/*/*.so ${prefix}/lib/gap/

install_license LICENSE
"""

sources, script = require_macos_sdk("10.14", sources, script)

name = gap_pkg_name(name)
dependencies = gap_pkg_dependencies(gap_version)
platforms = gap_platforms()
platforms = expand_cxxstring_abis(platforms)

push!(dependencies, Dependency("libsemigroups_jll", compat = "=3.5.3"))

# The products that we will ensure are always built
products = [
    FileProduct("lib/gap/semigroups.so", :semigroups),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"10")

# rebuild trigger: 1
