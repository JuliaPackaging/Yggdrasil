using BinaryBuilder

name = "CHICKEN"
version = v"5.4.0"

sources = [
    ArchiveSource("https://code.call-cc.org/releases/$version/chicken-$version.tar.gz",
                  "3c5d4aa61c1167bf6d9bf9eaf891da7630ba9f5f3c15bf09515a7039bfcdec5f")
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
    C_COMPILER_OPTIMIZATION_OPTIONS="${CFLAGS}"
    CXX_COMPILER=${CXX}
    LIBRARIAN=ar
    LINKER_OPTIONS="${LDFLAGS}"
    HOSTSYSTEM=${target}
    PREFIX=${prefix}
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
# Only disable the x86-64 if we're compiling for a different architecture
if [ "${tarch}" != "x86-64" ]; then
    OPTS+=(TARGET_FEATURES='"-no-feature x86-64 -feature ${tarch}"')
fi

make "${OPTS[@]}" install
"""

platforms = supported_platforms()

# NOTE: We could include Feathers, the graphical debugger, alongside the other products,
# but it's distributed as a .tcl file with an accompanying shell script that just invokes
# `wish`, and we would need to take a dependency on Tk_jll.
products = [
    ExecutableProduct("chicken", :chicken),
    ExecutableProduct("chicken-do", :chicken_do),
    ExecutableProduct("chicken-install", :chicken_install),
    ExecutableProduct("chicken-profile", :chicken_profile),
    ExecutableProduct("chicken-status", :chicken_status),
    ExecutableProduct("chicken-uninstall", :chicken_uninstall),
    ExecutableProduct("csc", :chicken_csc),
    ExecutableProduct("csi", :chicken_csi),
    FileProduct("libchicken.a", :libchicken_a),
    FileProduct("include/chicken.h", :chicken_h),
    FileProduct("include/chicken-config.h", :chicken_config_h),
    LibraryProduct("libchicken", :libchicken),
]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
