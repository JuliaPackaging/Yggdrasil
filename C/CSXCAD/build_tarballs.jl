using BinaryBuilder, Pkg

name = "CSXCAD"
version = v"0.6.3"

# ---------------------------------------------------------------------------
# Sources
# ---------------------------------------------------------------------------
sources = [
    GitSource(
        "https://github.com/thliebig/CSXCAD.git",
        "3861f2102aa9d13fbb0edb115fe446aeca6a0c13",  # tag v0.6.3
    ),
    DirectorySource("./bundled"),
]

# ---------------------------------------------------------------------------
# Build script
#
# Key cmake variables:
#   FPARSER_ROOT_DIR / FPARSER_INCLUDE_DIR  — required; no auto-detection
#   TinyXML_ROOT_DIR                        — for the custom FindTinyXML.cmake
#   CMAKE_PREFIX_PATH=$prefix               — covers HDF5, CGAL
#
# VTK: find_package(VTK REQUIRED ...) — hard dependency, cannot be omitted.
#
# Patch: CSPropDiscMaterial.cpp:330 uses bare 'cout' (missing std::) — upstream
# bug in v0.6.3 exposed by VTK 9.6 headers which no longer pull in
# 'using namespace std'.
# ---------------------------------------------------------------------------
script = raw"""
cd ${WORKSPACE}/srcdir/CSXCAD

# Fix bare 'cout' in CSPropDiscMaterial.cpp (upstream bug in v0.6.3)
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/fix_bare_cout.patch"

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DFPARSER_ROOT_DIR=${prefix} \
    -DFPARSER_INCLUDE_DIR=${prefix}/include \
    -DTinyXML_ROOT_DIR=${prefix}

cmake --build build --parallel ${nproc}
cmake --install build

install_license ${WORKSPACE}/srcdir/CSXCAD/COPYING
"""

# ---------------------------------------------------------------------------
# Platforms
# FreeBSD and musl excluded: CGAL requires Boost.GMP/MPFR not reliably
# available in those sysroots.
# ---------------------------------------------------------------------------
platforms = supported_platforms(; experimental = false)
filter!(p -> !(Sys.isfreebsd(p)), platforms)
filter!(p -> libc(p) != "musl", platforms)
platforms = expand_cxxstring_abis(platforms)

# ---------------------------------------------------------------------------
# Products
# ---------------------------------------------------------------------------
products = [
    LibraryProduct("libCSXCAD", :libCSXCAD),
]

# ---------------------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------------------
dependencies = [
    Dependency("Fparser_jll"),
    Dependency("TinyXML_jll"),
    Dependency("HDF5_jll"),
    Dependency("CGAL_jll"),
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
