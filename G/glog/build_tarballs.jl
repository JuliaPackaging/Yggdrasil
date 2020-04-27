using BinaryBuilder

name = "glog"
version = v"0.4.0"

sources = [
    ArchiveSource("https://github.com/google/glog/archive/v$(version).tar.gz",
                  "f28359aeba12f30d73d9e4711ef356dc842886968112162bc73002645139c39c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/glog-*

mkdir cmake_build
cd cmake_build/
FLAGS=()
if [[ "${target}" == i686-w64-mingw32 ]]; then
    # For some reasons, CMake can't find the symbol `UnDecorateSymbolName` in libdbghelp
    FLAGS+=(-DHAVE_DBGHELP=TRUE)
elif [[ "${target}" == *-freebsd* ]]; then
    # It looks like the build is broken with Clang for FreeBSD:
    #
    #   In file included from /workspace/srcdir/glog-0.4.0/src/utilities.cc:375:
    #   /workspace/srcdir/glog-0.4.0/src/stacktrace_x86_64-inl.h:64:6: error: use of undeclared identifier '_Unwind_Backtrace'
    #        _Unwind_Backtrace(nop_backtrace, NULL);
    #        ^
    #   /workspace/srcdir/glog-0.4.0/src/stacktrace_x86_64-inl.h:100:3: error: use of undeclared identifier '_Unwind_Backtrace'
    #     _Unwind_Backtrace(GetOneFrame, &targ);
    #     ^
    #   2 errors generated.
    #   make[2]: *** [CMakeFiles/glog.dir/build.make:115: CMakeFiles/glog.dir/src/utilities.cc.o] Error 1
    #
    CMAKE_TARGET_TOOLCHAIN=${CMAKE_TARGET_TOOLCHAIN%.*}_gcc.cmake
fi

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
      -DBUILD_SHARED_LIBS=ON \
      -DBUILD_TESTING=OFF \
      "${FLAGS[@]}" \
      ..

make -j${nproc}
make install

# Upstream PR from 30 Aug 2017 "Produce pkg-config file under cmake"
# See https://github.com/google/glog/pull/239 and #483, not released
mkdir ${prefix}/lib/pkgconfig
cat >${prefix}/lib/libglog.pc <<EOS
  prefix=${prefix}
  exec_prefix=${prefix}
  libdir=${libdir}
  includedir=${prefix}/include

  Name: libglog
  Description: Google Log (glog) C++ logging framework
  Version: 0.4.0
  Libs: -L${libdir} -lglog
  Cflags: -I${prefix}/include
EOS
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
# No products: Eigen is a pure header library
products = Product[
    LibraryProduct("libglog", :libglog),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
