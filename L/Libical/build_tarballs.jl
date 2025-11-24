# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Libical"
version = v"3.0.9"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/libical/libical/releases/download/v$(version)/libical-$(version).tar.gz",
                  "bd26d98b7fcb2eb0cd5461747bbb02024ebe38e293ca53a7dfdcb2505265a728"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libical-*
apk add libxml2-dev gtk-doc doxygen
# Hint to find libstc++, required to link against C++ libs when using C compiler
if [[ "${target}" == *-linux-* ]]; then
    if [[ "${nbits}" == 32 ]]; then
        export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib";
    else
        export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib64";     
    fi;
fi
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DICAL_GLIB="FALSE" \
    --disable-static \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(filter!(!Sys.isfreebsd, supported_platforms()))

# The products that we will ensure are always built
products = [
    LibraryProduct("libicalvcal", :libicalvcal),
    LibraryProduct("libicalss_cxx", :libicalss_cxx),
    LibraryProduct("libical_cxx", :libical_cxx),
    LibraryProduct("libicalss", :libicalss),
    LibraryProduct("libical", :libical)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="BerkeleyDB_jll", uuid="cd00e070-8fe2-570d-8212-aefc8f89bd06"))
    Dependency(PackageSpec(name="Glib_jll", uuid="7746bdde-850d-59dc-9ae8-88ece973131d"), v"2.59.0"; compat="2.59.0")
    Dependency(PackageSpec(name="ICU_jll", uuid="a51ab1cf-af8e-5615-a023-bc2c838bba6b"), v"68.2"; compat = "68.2")
    # We had to restrict compat with XML2 because of ABI breakage:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/10965#issuecomment-2798501268
    # Updating to `compat="~2.14.1"` is likely possible without problems but requires rebuilding this package
    Dependency(PackageSpec(name="XML2_jll", uuid="02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"); compat="~2.13.6")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7", julia_compat="1.6")
