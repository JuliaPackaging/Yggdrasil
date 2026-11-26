using BinaryBuilder2

name = "boost"
version = v"1.87.0"

# Collection of sources required to build boost
sources = [
    ArchiveSource(
        "https://archives.boost.io/release/$version/source/boost_$(version.major)_$(version.minor)_$(version.patch).tar.bz2",
        "af57be25cb4c4f4b413ed692fe378affb4352ea50fbe294a11ef548f4d527d89"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/boost*

# bootstrap.sh clears CXX/CXXFLAGS, so pass -pthread (needed to link the B2 engine's C++11
# check with the BB2 host compiler) through the toolset string, which is word-split.
# The B2 engine is built for the build machine; on mingw targets its build.sh sees a
# mingw `-dumpmachine` from the wrapped compiler and tries to embed a Windows resource.
export B2_DONT_EMBED_MANIFEST=1
./bootstrap.sh --prefix=$prefix --without-libraries=python --with-toolset="--cxx=${HOST_CXX} --cxxflags=-pthread"

rm project-config.jam

# On x86 and powerpc64le (the targets whose toolchain ships libquadmath), boost.charconv would
# link libquadmath (its has_float128 check passes), but only the old-style
# CompilerSupportLibraries_jll provides it and the BB2 audit cannot map libraries to
# JLLs without a JLL.toml.  So make the check fail there: libboost_charconv is then built
# WITHOUT __float128 conversion support (the previous boost_jll had it).  Remove this once
# libquadmath is available as a BB2 dependency, see
# https://github.com/JuliaPackaging/Yggdrasil/issues/15815.
if [[ $target == x86_64-* || $target == i686-* || $target == powerpc64le-* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/charconv-no-float128.patch
fi
toolset=gcc
targetos=linux
extraargs=
without_libs=

# BinaryBuilderBase compiler wrappers don't like it when we use -march=ANYTHING.
# So we patch that out. However, we cannot just insert an empty string; so we instead
# add another "harmless" option; we choose `-Wall` which is already passed anyway
sed -i "s/-march=i686/-Wall/g" tools/build/src/tools/gcc.*

# We need `-Wno-enum-constexpr-conversion` to disable a Clang
# "warning" that is actually an error. (This is a problem in Boost which
# violates the C++17 standard.)

if [[ $target == *apple* ]]; then
    targetos=darwin
    # The bare `libtool` on PATH is GNU libtool (host tools), which rejects `-static`; b2's
    # darwin toolset needs the cctools one, which is not on PATH, so locate it.
    CCTOOLS_LIBTOOL=$(ls /opt/target-${target}/*/bin/*-apple-darwin*-libtool | head -1)
    echo "Using cctools libtool: ${CCTOOLS_LIBTOOL}"
    toolset=darwin-6.0
    extraargs="binary-format=mach-o link=shared"
    echo "using darwin : 6.0 : $CXX : <cxxflags>\\"-stdlib=libc++ -Wno-enum-constexpr-conversion\\" <linkflags>-stdlib=libc++ <archiver>${CCTOOLS_LIBTOOL} ;" > project-config.jam
    if [[ "${target}" == aarch64-* ]]; then
        # Fix error
        #     Undefined symbols for architecture arm64:
        #       "_jump_fcontext", referenced from:
        # See https://github.com/boostorg/context/issues/170#issuecomment-863669877
        extraargs="abi=aapcs ${extraargs}"
    elif [[ "${target}" == x86_64-* ]]; then
        # Without these, boost.context selects no assembly for x86_64 macOS and fails with
        #     Undefined symbols for architecture x86_64: "_jump_fcontext"
        extraargs="abi=sysv address-model=64 architecture=x86 ${extraargs}"
    fi
elif [[ $target == *mingw* ]]; then
    targetos=windows
    echo "using gcc : 11.1 : $CXX : <cxxflags>\\"-DWINVER=0x0603 -DBOOST_USE_WINAPI_VERSION=0x0603 -D_WIN32_WINNT=0x0603 -DBOOST_STACKTRACE_USE_WINDBG=1\\" <linkflags>\\"-DBOOST_STACKTRACE_USE_WINDBG=1 -ldl -lstdc++\\" ;" > project-config.jam

    if [[ $target == x86_64*mingw* ]]; then
        extraargs="address-model=64 binary-format=pe abi=ms link=shared threadapi=win32"
    elif [[ $target == i686*mingw* ]]; then
        extraargs="address-model=32 binary-format=pe abi=ms link=shared threadapi=win32"
    fi
elif [[ $target == i686*linux* ]]; then
    extraargs='cxxflags="-DBOOST_STACKTRACE_LIBCXX_RUNTIME_MAY_CAUSE_MEMORY_LEAK=1"'
elif [[ $target == *freebsd* ]]; then
    targetos=freebsd
    # BB2's FreeBSD sysroot only ships libc and libthr.  boost.chrono and boost.log ask for
    # `-lrt`, whose functions live in libc on FreeBSD, so provide an empty librt for the link;
    # boost.process needs libkvm and libprocstat (which have real contents), and is not one of
    # our products, so skip it.
    mkdir -p ${libdir}
    ${AR} rcs ${libdir}/librt.a
    without_libs="--without-process"
    toolset=clang-6.0
    extraargs="address-model=64 link=shared"
    if [[ "${target}" == aarch64-* ]]; then
        extraargs="abi=aapcs ${extraargs}"
    fi
    echo "using clang : 6.0 : $CXX : <cxxflags>\\"-Wno-enum-constexpr-conversion\\" <linkflags>\\"${LDFLAGS:-}\\" ;" > project-config.jam
elif [[ $target == armv* ]]; then
    extraargs="abi=aapcs ${extraargs}"
fi

b2_args=(
    -j${nproc}
    toolset=$toolset
    target-os=$targetos
    $extraargs
    variant=release
    --prefix=$prefix
    --without-python
    ${without_libs:-}
    --layout=system
    --debug-configuration install
    -d0 # Limit logging output
    --libdir=${libdir}
    --includedir=${includedir}
    -sZLIB_INCLUDE=${includedir}
    -sZLIB_LIBPATH=${libdir}
    -sBZIP2_INCLUDE=${includedir}
    -sBZIP2_LIBPATH=${libdir}
)

./b2 "${b2_args[@]}"

if [[ $target == *mingw* ]]; then
    # b2 installs the DLLs next to the import libraries in lib/, but Windows loads DLLs from bin/
    mkdir -p ${bindir}
    mv ${libdir}/*.dll ${bindir}/
fi

if [[ $target == *freebsd* ]]; then
    # the empty stand-in made above only satisfied -lrt at link time; do not ship it
    rm -f ${libdir}/librt.a
fi

install_license LICENSE_1_0.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libboost_atomic", :libboost_atomic),
    LibraryProduct("libboost_chrono", :libboost_chrono),
    LibraryProduct("libboost_container", :libboost_container),
    LibraryProduct("libboost_context", :libboost_context),
    LibraryProduct("libboost_contract", :libboost_contract),
    LibraryProduct("libboost_coroutine", :libboost_coroutine),
    LibraryProduct("libboost_date_time", :libboost_date_time),
    LibraryProduct("libboost_filesystem", :libboost_filesystem),
    LibraryProduct("libboost_graph", :libboost_graph),
    LibraryProduct("libboost_iostreams", :libboost_iostreams),
    # boost_locale segfaults on windows, see https://github.com/benlorenz/boostBuilder/issues/2
    # LibraryProduct("libboost_locale", :libboost_locale),
    LibraryProduct("libboost_log", :libboost_log),
    LibraryProduct("libboost_log_setup", :libboost_log_setup),
    LibraryProduct("libboost_prg_exec_monitor", :libboost_prg_exec_monitor),
    LibraryProduct("libboost_program_options", :libboost_program_options),
    LibraryProduct("libboost_random", :libboost_random),
    LibraryProduct("libboost_regex", :libboost_regex),
    LibraryProduct("libboost_serialization", :libboost_serialization),
    LibraryProduct("libboost_stacktrace_basic", :libboost_stacktrace_basic),
    LibraryProduct("libboost_stacktrace_noop", :libboost_stacktrace_noop),
    LibraryProduct("libboost_system", :libboost_system),
    LibraryProduct("libboost_thread", :libboost_thread),
    LibraryProduct("libboost_timer", :libboost_timer),
    LibraryProduct("libboost_type_erasure", :libboost_type_erasure),
    LibraryProduct("libboost_unit_test_framework", :libboost_unit_test_framework),
    LibraryProduct("libboost_wave", :libboost_wave),
    LibraryProduct("libboost_wserialization", :libboost_wserialization),
]

# Under BinaryBuilder2 a project can only depend on other BinaryBuilder2 projects: the auditor
# needs a `JLL.toml` for every dependency.  Zlib_jll 1.4.2, Bzip2_jll 1.0.10 and
# dlfcn_win32_jll 1.4.3 are the BinaryBuilder2 builds.
target_dependencies = [
    JLLSource("Zlib_jll"; version=v"1.4.2"),
    JLLSource("Bzip2_jll"; version=v"1.0.10"),
]

# JLLSource has no platform filter, so dlfcn_win32_jll (needed on Windows only) is added
# through a custom build spec generator instead of `target_dependencies`.
build_spec_generator = (host, platform) -> BinaryBuilder2.default_build_spec_generator(;
    target_toolchains = [CToolchain(), CMakeToolchain()],
    host_toolchains = [CToolchain(), CMakeToolchain(), HostToolsToolchain()],
    target_dependencies,
    target_build_time_dependencies = Sys.iswindows(platform) ? [JLLSource("dlfcn_win32_jll"; version=v"1.4.3")] : [],
    host_dependencies = [],
    cross_compiler = isa(platform, CrossPlatform),
)(host, platform)

build_tarballs(;
    src_name = name,
    src_version = version,
    sources,
    script,
    platforms,
    products,
    build_spec_generator,
    # The libraries need CXXABI_1.3.15 (libstdc++ 6.0.33), first bundled with Julia 1.12; the
    # `julia_libstdcxx` audit rejects a lower `julia_compat`.
    julia_compat = "1.12",
)
