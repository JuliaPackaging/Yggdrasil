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
    # There are three Windows-related values recognized here: mingw, mingw-msys, and
    # linux-cross-mingw. The first assumes backslash path delimiters when building, which
    # doesn't work in the BinaryBuilder environment; the second assumes cmd.exe names and
    # backslash path delimiters for compiled code running on the target, which is maybe
    # fine; and the last builds a compiler that emits binaries for Windows, but the compiler
    # itself is intended to run on Linux, which is not what we want.
    PLATFORM=mingw-msys
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
    FileProduct("lib/libchicken.a", :libchicken_a),
    FileProduct("include/chicken/chicken.h", :chicken_h),
    FileProduct("include/chicken/chicken-config.h", :chicken_config_h),
    LibraryProduct("libchicken", :libchicken),
]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
