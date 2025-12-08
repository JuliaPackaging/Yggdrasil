using BinaryBuilder, Pkg

name = "libosrmc"
version = v"6.0.0"

sources = [
    GitSource("https://github.com/moviro-hub/libosrmc.git", "8ba3109261c1d30b06b1ef7f9741eb04fcc3aad7"),
]

script = raw"""
cd ${WORKSPACE}/srcdir
[[ -d "libosrmc/libosrmc" ]] && cd libosrmc/libosrmc || cd libosrmc

# Set PKG_CONFIG_PATH for OSRM discovery
export PKG_CONFIG_PATH="${prefix}/lib/pkgconfig:${PKG_CONFIG_PATH}"

# macOS-specific setup
if [[ "${target}" == *-apple-* ]]; then
    export MACOSX_DEPLOYMENT_TARGET=11.0
    export EXTRA_CXXFLAGS="-mmacosx-version-min=${MACOSX_DEPLOYMENT_TARGET}"
fi

# Build using Makefile
make clean
make -j${nproc} PREFIX=${prefix}
make install PREFIX=${prefix}
"""

platforms = supported_platforms()
# Linux, macOS (ARM only), Windows
platforms = filter(p -> Sys.islinux(p) || Sys.isapple(p) && arch(p) == "aarch64" || Sys.iswindows(p), platforms)
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libosrmc", :libosrmc; dont_dlopen = true),
    FileProduct("include/osrmc/osrmc.h", :osrmc_header),
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    # TODO: change to OSRM_jll.jl once released
    Dependency(PackageSpec(name="OSRM_jll", url="https://github.com/jrklasen/OSRM_jll.jl", rev="main")),
    Dependency("boost_jll"; compat="=1.87.0"),
    Dependency("Expat_jll"; compat="2.6.5"),
    Dependency("Zlib_jll"),
    Dependency("Bzip2_jll"),
]

build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    julia_compat="1.10",
    preferred_gcc_version = v"13",
)
