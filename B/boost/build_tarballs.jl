# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "boost"
version = v"1.71.0"

# Collection of sources required to build boost
sources = [
    "https://dl.bintray.com/boostorg/release/$(version)/source/boost_$(version.major)_$(version.minor)_$(version.patch).tar.bz2" =>
    "d73a8da01e8bf8c7eda40b4c84915071a8c8a0df4a6734537ddde4a8580524ee",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/boost*/

CXX=$CXX_FOR_BUILD ./bootstrap.sh --prefix=$prefix --without-libraries=python --with-toolset=gcc

rm project-config.jam
toolset=gcc
targetos=linux
extraargs=

if [[ $target == *apple* ]]; then
    targetos=darwin
    toolset=darwin-6.0
    extraargs="binary-format=mach-o link=shared"
    echo "using darwin : 6.0 : $CXX : <cxxflags>-stdlib=libc++ <linkflags>-stdlib=libc++ ;" > project-config.jam
elif [[ $target == x86_64*mingw* ]]; then
    targetos=windows
    extraargs="address-model=64 binary-format=pe abi=ms link=shared"
elif [[ $target == i686*mingw* ]]; then
    targetos=windows
    extraargs="address-model=32 binary-format=pe abi=ms link=shared"
elif [[ $target == *freebsd* ]]; then
    targetos=freebsd
    toolset=clang-6.0
    extraargs="address-model=64 link=shared"
    echo "using clang : 6.0 : $CXX : <linkflags>\\"$LDFLAGS\\" ;" > project-config.jam
fi
./b2 -j8 toolset=$toolset target-os=$targetos $extraargs variant=release --prefix=$prefix --without-python --layout=system install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p -> !isa(p, FreeBSD), supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libboost_math_tr1f", :libboost_math_tr1f),
    LibraryProduct("libboost_thread", :libboost_thread),
    LibraryProduct("libboost_unit_test_framework", :libboost_unit_test_framework),
    LibraryProduct("libboost_type_erasure", :libboost_type_erasure),
    LibraryProduct("libboost_chrono", :libboost_chrono),
    LibraryProduct("libboost_math_c99l", :libboost_math_c99l),
    # boost_locale segfaults on windows, see #2
    #LibraryProduct("libboost_locale", :libboost_locale),
    LibraryProduct("libboost_program_options", :libboost_program_options),
    LibraryProduct("libboost_date_time", :libboost_date_time),
    LibraryProduct("libboost_graph", :libboost_graph),
    LibraryProduct("libboost_iostreams", :libboost_iostreams),
    LibraryProduct("libboost_system", :libboost_system),
    LibraryProduct("libboost_wave", :libboost_wave),
    LibraryProduct("libboost_wserialization", :libboost_wserialization),
    LibraryProduct("libboost_math_tr1l", :libboost_math_tr1l),
    LibraryProduct("libboost_math_tr1", :libboost_math_tr1),
    LibraryProduct("libboost_filesystem", :libboost_filesystem),
    LibraryProduct("libboost_random", :libboost_random),
    LibraryProduct("libboost_coroutine", :libboost_coroutine),
    LibraryProduct("libboost_serialization", :libboost_serialization),
    LibraryProduct("libboost_context", :libboost_context),
    LibraryProduct("libboost_container", :libboost_container),
    LibraryProduct("libboost_stacktrace_noop", :libboost_stacktrace_noop),
    LibraryProduct("libboost_contract", :libboost_contract),
    LibraryProduct("libboost_prg_exec_monitor", :libboost_prg_exec_monitor),
    LibraryProduct("libboost_regex", :libboost_regex),
    LibraryProduct("libboost_log_setup", :libboost_log_setup),
    LibraryProduct("libboost_math_c99", :libboost_math_c99),
    LibraryProduct("libboost_timer", :libboost_timer),
    LibraryProduct("libboost_stacktrace_basic", :libboost_stacktrace_basic),
    LibraryProduct("libboost_math_c99f", :libboost_math_c99f),
    LibraryProduct("libboost_log", :libboost_log),
    LibraryProduct("libboost_atomic", :libboost_atomic)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

