# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Conduit"
version = v"0.8.1"
sources = [
    ArchiveSource("https://github.com/LLNL/conduit/releases/download/v$(version)/conduit-v$(version)-src-with-blt.tar.gz",
		  "488f22135a35136de592173131d123f7813818b7336c3b18e04646318ad3cbee")
]

# Note: we need to build the (optional) webserver by default until v0.8.1 is released
script = raw"""
cd ${WORKSPACE}/srcdir/conduit*
rm -rf build && mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      -DENABLE_TESTS=OFF \
      -DENABLE_EXAMPLES=OFF \
      -DENABLE_UTILS=OFF \
      -DENABLE_DOCS=OFF \
      -DENABLE_RELAY_WEBSERVER=OFF \
      -DENABLE_COVERAGE=OFF \
      -DENABLE_PYTHON=OFF \
      -DENABLE_FORTRAN=OFF \
      -DENABLE_MPI=OFF \
      ../src
make -j${nproc}
make install
"""

platforms = expand_cxxstring_abis(supported_platforms())

products = [
    LibraryProduct("libconduit", :libconduit),
    LibraryProduct("libconduit_blueprint", :libconduit_blueprint),
    LibraryProduct("libconduit_relay", :libconduit_relay),
]

dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
	       julia_compat="1.6", preferred_gcc_version=v"5")
