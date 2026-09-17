using BinaryBuilder

name = "CHICKEN"
version = v"6.0.0"

sources = [
    ArchiveSource("https://code.call-cc.org/releases/$version/chicken-$version.tar.gz",
                  "92835552b1b687ad26737e429b5aba36510bf429f8816ec0f6d336c8cb41f443")
]

script = raw"""
cd ${WORKSPACE}/srcdir/chicken*

if [[ ${target} == *-apple-* ]]; then
    PLATFORM=macosx
elif [[ ${target} == *-freebsd* ]]; then
    PLATFORM=bsd
elif [[ ${target} == *-mingw* ]]; then
    PLATFORM=mingw
else
    PLATFORM=linux
fi

OPTS=(
    ARCH=
    PLATFORM=${PLATFORM}
    C_COMPILER=${CC}
    CXX_COMPILER=${CXX}
    LIBRARIAN=ar
    HOSTSYSTEM=${target}
    PREFIX=
    DESTDIR=${prefix}
)

# Translate what we call the target architecture into what Chicken calls it
tarch="$(echo "${target}" | cut -d '-' -f 1 | tr _ -)"
if [ "${tarch}" = "i686" ]; then
    tarch="x86"
elif [ "${tarch}" = "aarch64" ]; then
    tarch="arm64"
elif [[ ${tarch} == armv* ]]; then
    tarch="arm"
elif [ "${tarch}" = "powerpc64le" ]; then
    tarch="ppc64"
fi

# Only disable the x86-64 if we're compiling for a different architecture. I can't for the
# life of me get the quoting to work correctly for the target feature specification when
# putting it into the array, so I'll just admit defeat and separate the `make` calls.
if [ "${tarch}" = "x86-64" ]; then
    make "${OPTS[@]}" install
else
    make "${OPTS[@]}" TARGET_FEATURES="-no-feature x86-64 -feature ${tarch}" install
fi
"""

platforms = supported_platforms()

products = [
    ExecutableProduct("chicken", :chicken),
    ExecutableProduct("chicken-do", :chicken_do),
    ExecutableProduct("chicken-install", :chicken_install),
    ExecutableProduct("chicken-profile", :chicken_profile),
    ExecutableProduct("chicken-status", :chicken_status),
    ExecutableProduct("chicken-uninstall", :chicken_uninstall),
    ExecutableProduct("csc", :chicken_csc),
    ExecutableProduct("csi", :chicken_csi),
    FileProduct("lib/libchicken.a", :libchicken_a),
    FileProduct("include/chicken/chicken.h", :chicken_h),
    FileProduct("include/chicken/chicken-config.h", :chicken_config_h),
    LibraryProduct("libchicken", :libchicken),
]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
