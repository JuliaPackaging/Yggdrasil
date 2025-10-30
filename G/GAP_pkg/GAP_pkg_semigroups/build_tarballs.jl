# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../common.jl")

gap_version = v"400.1500.0"
name = "semigroups"
upstream_version = "5.5.4" # when you increment this, reset offset to v"0.0.0"
offset = v"1.0.0" # increment this when rebuilding with unchanged upstream_version, e.g. gap_version changes
version = offset_version(upstream_version, offset)

# Collection of sources required to build this JLL
sources = [
    ArchiveSource("https://github.com/semigroups/Semigroups/releases/download/v$(upstream_version)/semigroups-$(upstream_version).tar.gz",
                  "df0488b14af106338009c0ae7dc8b7def9052fb3619a6ba53c31f60cc0731353"),
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
elif [[ "${target}" == *-freebsd* ]]; then
    # backward-cpp doesn't support freebsd
    EXTRA_FLAGS+=(--disable-backward)
fi

# not enough space in /tmp on buildkite
export TMPDIR=$WORKSPACE/tmp
mkdir $TMPDIR

./configure \
    --build=${MACHTYPE} \
    --host=${target} \
    --with-gaproot=${prefix}/lib/gap \
    --disable-hpcombi \
    "${EXTRA_FLAGS[@]}"
make -j${nproc}

# copy the loadable module
mkdir -p ${prefix}/lib/gap
cp bin/*/*.so ${prefix}/lib/gap/
cp bin/lib/*.* ${prefix}/lib/gap/

install_license LICENSE
"""

name = gap_pkg_name(name)
dependencies = gap_pkg_dependencies(gap_version)
platforms = gap_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    FileProduct("lib/gap/semigroups.so", :semigroups),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"7")

# rebuild trigger: 1
