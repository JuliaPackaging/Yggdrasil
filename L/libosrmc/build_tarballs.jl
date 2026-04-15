using BinaryBuilder, Pkg

include(joinpath("..", "..", "platforms", "macos_sdks.jl"))

name = "libosrmc"
version = v"26.4.0"

sources = [
    GitSource("https://github.com/moviro-hub/libosrmc.git", "40473483dbe07bff05e6a5b640226c99fe5271dd"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/libosrmc/libosrmc

# Set PKG_CONFIG_PATH for OSRM discovery
export PKG_CONFIG_PATH="${prefix}/lib/pkgconfig:${PKG_CONFIG_PATH}"

# Build using Makefile
make -j${nproc} PREFIX=${prefix}
make install PREFIX=${prefix}

install_license "${WORKSPACE}/srcdir/libosrmc/LICENSE"
"""

platforms = supported_platforms()
platforms = filter(p -> !Sys.isfreebsd(p), platforms)
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libosrmc", :libosrmc; dont_dlopen = true),
    FileProduct("include/osrmc/osrmc.h", :osrmc_header),
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OSRM_jll"; compat = "~26.4.0"),
    Dependency("boost_jll"; compat = "=1.87.0"),
    Dependency("Expat_jll"; compat = "2.6.5"),
    Dependency("Zlib_jll"),
    Dependency("Bzip2_jll"),
]

sources, script = require_macos_sdk("10.15", sources, script)

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat = "1.10", preferred_gcc_version = v"13",
)
