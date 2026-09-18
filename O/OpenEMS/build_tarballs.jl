using BinaryBuilder, Pkg

name = "OpenEMS"
version = v"0.0.36"

# ---------------------------------------------------------------------------
# Sources
# ---------------------------------------------------------------------------
sources = [
    GitSource(
        "https://github.com/thliebig/openEMS.git",
        "5f36e7f3a2367123f00999491a069aed50c6f244",  # tag v0.0.36
    ),
]

# ---------------------------------------------------------------------------
# Build script
#
# Key cmake variables:
#   FPARSER_ROOT_DIR / FPARSER_INCLUDE_DIR  — fparser is not auto-detected
#   CSXCAD_ROOT_DIR / CSXCAD_INCLUDE_DIR    — CSXCAD is not auto-detected
#   CSXCAD_INCLUDE_DIR must point to ${prefix}/include/CSXCAD (not ${prefix}/include)
#   CMAKE_PREFIX_PATH=$prefix               — covers TinyXML, HDF5, Boost
#   WITH_MPI=OFF                            — disable MPI for portability
# ---------------------------------------------------------------------------
script = raw"""
cd ${WORKSPACE}/srcdir/openEMS

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DFPARSER_ROOT_DIR=${prefix} \
    -DFPARSER_INCLUDE_DIR=${prefix}/include \
    -DCSXCAD_ROOT_DIR=${prefix} \
    -DCSXCAD_INCLUDE_DIR=${prefix}/include/CSXCAD \
    -DWITH_MPI=OFF

cmake --build build --parallel ${nproc}
cmake --install build

install_license ${WORKSPACE}/srcdir/openEMS/COPYING
"""

# ---------------------------------------------------------------------------
# Platforms — same constraints as CSXCAD_jll
# ---------------------------------------------------------------------------
platforms = supported_platforms(; experimental = false)
filter!(p -> !(Sys.isfreebsd(p)), platforms)
filter!(p -> libc(p) != "musl", platforms)
platforms = expand_cxxstring_abis(platforms)

# ---------------------------------------------------------------------------
# Products
# ---------------------------------------------------------------------------
products = [
    LibraryProduct("libopenEMS", :libopenEMS),
    ExecutableProduct("openEMS", :openEMS_bin),
]

# ---------------------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------------------
dependencies = [
    Dependency("Fparser_jll"),
    Dependency("CSXCAD_jll"),
    Dependency("TinyXML_jll"),
    Dependency("HDF5_jll"),
    Dependency("boost_jll"),
    Dependency("VTK_jll"),
    BuildDependency("Zlib_jll"),
]

build_tarballs(
    ARGS,
    name, version, sources, script, platforms, products, dependencies;
    julia_compat = "1.6",
    preferred_gcc_version = v"9",
)
