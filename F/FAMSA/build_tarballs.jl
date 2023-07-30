using BinaryBuilder, Pkg

name = "FAMSA"
version = v"2.2.2"

# url = "https://github.com/refresh-bio/FAMSA"
# description = "Algorithm for ultra-scale multiple sequence alignments"

# Compilation failures (gcc-10)
# - disabled all arch except ["x86_64", "aarch64", "powerpc64le"]
# - failed builds (fail with gcc-10, works with gcc-11):
#   armv6l-linux-*
#   armv7l-linux-*
#   i686-linux-*

# Compilation failures (gcc-11)
#
# - x86_64-w64-mingw32-cxx11
#
#   [01:56:42] In file included from src/utils/timer.cpp:14:
#   [01:56:42] src/utils/timer.h:47:10: fatal error: sys/resource.h: No such file or directory
#   [01:56:42]    47 | #include <sys/resource.h>
#   [01:56:42]       |          ^~~~~~~~~~~~~~~~
#
# - x86_64-unknown-freebsd
#
#   [01:37:02] src/tree/MSTPrim.cpp:211:21: error: no member named 'test' in 'std::atomic_flag'
#   [01:37:02]                                         while (b_flag0.test(memory_order_relaxed) == flag_value)
#   [01:37:02]                                                ~~~~~~~ ^
#   [01:37:02] src/tree/MSTPrim.cpp:499:21: error: no member named 'test' in 'std::atomic_flag'
#   [01:37:02]                                         while (b_flag0.test(memory_order_relaxed) == flag_value)
#   [01:37:02]                                                ~~~~~~~ ^
#
#   [01:37:05] In file included from src/core/profile_par.cpp:39:
#   [01:37:05] In file included from libs/../libs/atomic_wait/barrier:28:
#   [01:37:05] libs/../libs/atomic_wait/atomic_wait:330:13: error: use of undeclared identifier '__YIELD_PROCESSOR'
#   [01:37:05]             __YIELD_PROCESSOR();
#   [01:37:05]             ^
#   [01:37:05] libs/../libs/atomic_wait/atomic_wait:332:13: error: use of undeclared identifier '__YIELD'
#   [01:37:05]             __YIELD();
#   [01:37:05]             ^

sources = [
    # v2.2.2
    GitSource("https://github.com/refresh-bio/FAMSA",
              "7eb7612c661362747709021e3a9ff2c2d89bbdca"),
    DirectorySource("./bundled")
]

script = raw"""
cd $WORKSPACE/srcdir/FAMSA*/

atomic_patch -p1 ../patches/fix-makefile-avx2-platform-no-march.patch

PLATFORM=none
if [[ ${target} == x86_64-* || ${target} == i686-* ]]; then
    PLATFORM=avx2
elif [[ ${target} == aarch64-apple-darwin* ]]; then
    PLATFORM=m1
elif [[ ${target} == aarch64-linux-* ]]; then
    PLATFORM=arm8
else
    echo "WARNING: not using any hardware accelleration, PLATFORM=$PLATFORM"
fi

UNAME_S=
if [[ ${target} == *-apple-darwin* ]]; then
    UNAME_S=Darwin
fi

make -j${nproc} CC=${CC} CXX=${CXX} PLATFORM=${PLATFORM} UNAME_S=${UNAME_S}
install -Dvm 755 "famsa${exeext}" "${bindir}/famsa${exeext}"
install_license LICENSE
"""

platforms = supported_platforms(;
    exclude = p -> Sys.iswindows(p) || Sys.isfreebsd(p) || nbits(p) == 32
)
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("famsa", :famsa)
]

dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"10")
