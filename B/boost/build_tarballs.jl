# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "boost"
version = v"1.87.0"

# Collection of sources required to build boost
sources = [
    ArchiveSource(
        "https://archives.boost.io/release/$version/source/boost_$(version.major)_$(version.minor)_$(version.patch).tar.bz2",
        "af57be25cb4c4f4b413ed692fe378affb4352ea50fbe294a11ef548f4d527d89"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/boost*

./bootstrap.sh --prefix=$prefix --without-libraries=python --with-toolset="--cxx=${CXX_FOR_BUILD}"

rm project-config.jam
toolset=gcc
targetos=linux
extraargs=

# BinaryBuilderBase compiler wrappers don't like it when we use -march=ANYTHING.
# So we patch that out. However, we cannot just insert an empty string; so we instead
# add another "harmless" option; we choose `-Wall` which is already passed anyway
sed -i "s/-march=i686/-Wall/g" tools/build/src/tools/gcc.*

# We need `-Wno-enum-constexpr-conversion` to disable a Clang
# "warning" that is actually an error. (This is a problem in Boost which
# violates the C++17 standard.)

if [[ $target == *apple* ]]; then
    targetos=darwin
    toolset=darwin-6.0
    extraargs="binary-format=mach-o link=shared"
    echo "using darwin : 6.0 : $CXX : <cxxflags>\\"-stdlib=libc++ -Wno-enum-constexpr-conversion\\" <linkflags>-stdlib=libc++ ;" > project-config.jam
    if [[ "${target}" == aarch64-* ]]; then
        # Fix error
        #     Undefined symbols for architecture arm64:
        #       "_jump_fcontext", referenced from:
        # See https://github.com/boostorg/context/issues/170#issuecomment-863669877
        extraargs="abi=aapcs ${extraargs}"
    fi
elif [[ $target == *mingw* ]]; then
    targetos=windows
    echo "using gcc : 8.1 : $CXX : <cxxflags>\\"-DBOOST_USE_WINAPI_VERSION=0x0603 -D_WIN32_WINNT=0x0603 -DBOOST_STACKTRACE_USE_WINDBG=1\\" <linkflags>\\"-DBOOST_STACKTRACE_USE_WINDBG=1\\" ;" > project-config.jam

    if [[ $target == x86_64*mingw* ]]; then
        extraargs="address-model=64 binary-format=pe abi=ms link=shared"
    elif [[ $target == i686*mingw* ]]; then
        extraargs="address-model=32 binary-format=pe abi=ms link=shared"
    fi
elif [[ $target == i686*linux* ]]; then
    extraargs='cxxflags="-DBOOST_STACKTRACE_LIBCXX_RUNTIME_MAY_CAUSE_MEMORY_LEAK=1"'
elif [[ $target == *freebsd* ]]; then
    targetos=freebsd
    toolset=clang-6.0
    extraargs="address-model=64 link=shared"
    if [[ "${target}" == aarch64-* ]]; then
        extraargs="abi=aapcs ${extraargs}"
    fi
    echo "using clang : 6.0 : $CXX : <cxxflags>\\"-Wno-enum-constexpr-conversion\\" <linkflags>\\"$LDFLAGS\\" ;" > project-config.jam
elif [[ $target == armv* ]]; then
    extraargs="abi=aapcs ${extraargs}"
fi
./b2 -j${nproc} toolset=$toolset target-os=$targetos $extraargs variant=release --prefix=$prefix --without-python --layout=system --debug-configuration install -q --without-mpi

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
    #LibraryProduct("libboost_locale", :libboost_locale),
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

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
    BuildDependency("dlfcn_win32_jll"; platforms = filter(Sys.iswindows, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8", julia_compat="1.6")

# Build trigger: 1
