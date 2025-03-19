# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Conduit"
version = v"0.9.3"
sources = [
    ArchiveSource("https://github.com/LLNL/conduit/releases/download/v$(version)/conduit-v$(version)-src-with-blt.tar.gz",
		  "2968fa8df6e6c43800c019a008ef064ee9995dc2ff448b72dc5017c188a2e6d4")
]

# Note: we need to build the (optional) webserver by default until v0.8.1 is released
script = raw"""
cd ${WORKSPACE}/srcdir/conduit*
cmake -Bbuild \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      -DENABLE_TESTS=OFF \
      -DENABLE_EXAMPLES=OFF \
      -DENABLE_UTILS=ON \
      -DENABLE_DOCS=OFF \
      -DENABLE_RELAY_WEBSERVER=OFF \
      -DENABLE_COVERAGE=OFF \
      -DENABLE_PYTHON=OFF \
      -DENABLE_FORTRAN=OFF \
      -DENABLE_MPI=OFF \
      -DENABLE_OpenMP=ON \
      -DCONDUIT_ENABLE_TESTS=OFF \
      src
cmake --build build --parallel ${nproc}
cmake --install build
"""

platforms = expand_cxxstring_abis(supported_platforms())

products = [
    LibraryProduct("libconduit", :libconduit),
    LibraryProduct("libconduit_blueprint", :libconduit_blueprint),
    LibraryProduct("libconduit_relay", :libconduit_relay),
]

# We could additional depend on
# - ADIOS (would require MPI)
# - HDF5 (would require MPI)
# - MPI
# - Silo (not an Yggdrasil package)
# - Parmetis (would require MPI)

dependencies = [
    Dependency(PackageSpec(name="Zlib_jll")),
    Dependency(PackageSpec(name="zfp_jll"); compat="1.0.1"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
	       julia_compat="1.6", preferred_gcc_version=v"5")
