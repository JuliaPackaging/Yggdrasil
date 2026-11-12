# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# Taken from C/Coin-OR/coin-or-common.jl.
"""
    offset_version(upstream, offset)

Compute a version that allows distinguishing between changes in the upstream
version and changes to the JLL which retain the same upstream version.

When the `upstream` version is changed, `offset` version numbers should be reset
to `v"0.0.0"` and incremented following semantic versioning.
"""
function offset_version(upstream, offset)
    return VersionNumber(
        upstream.major * 100 + offset.major,
        upstream.minor * 100 + offset.minor,
        upstream.patch * 100 + offset.patch,
    )
end

upstream_version = v"1.0.0"
version_offset = v"0.0.0"
version = offset_version(upstream_version, version_offset)

# Collection of sources required to complete build
sources = [
    GitSource(
        "https://github.com/osqp/osqp.git",
        "236713ce9a56c182ac3230d52108f952afce1523",
    ),
]

common_deps = [
    HostBuildDependency(PackageSpec(; name="CMake_jll"))
]

"""
    init_env_script()

Generate the script to use to initialize the build environment and apply the patches
to the source code.
"""
function init_env_script()
    raw"""
# OSQP requires CMake > 3.18, the base image has 3.17.2 currently, so use the JLL-provided CMake
apk del cmake

cd $WORKSPACE/srcdir/osqp
git submodule update --init --recursive

# Apply any patches
for p in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 "${p}" || true
done
"""
end

"""
    build_script(; algebra::String, suffix::String, usefloat::Bool, builddir::String = "build")

Generate the build script to use to build OSQP depending on the options desired.
"""
function build_script(; algebra::String, suffix::String, usefloat::Bool, builddir::String = "build")
    """
    OSQP_VERSION=\"$(upstream_version)\"
    OSQP_ALGEBRA=\"$(algebra)\"
    OSQP_LIB_SUFFIX=\"$(suffix)\"
    OSQP_FLOAT=$(usefloat ? "ON" : "OFF")
    BUILD_DIR=\"$(builddir)\"
    """ *
    raw"""
mkdir $BUILD_DIR
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DOSQP_BUILD_UNITTESTS=OFF \
    -DOSQP_VERSION=$OSQP_VERSION \
    -DOSQP_BUILD_SHARED_LIB=ON \
    -DOSQP_BUILD_STATIC_LIB=OFF \
    -DOSQP_ALGEBRA_BACKEND=$OSQP_ALGEBRA \
    -DOSQP_USE_FLOAT=$OSQP_FLOAT \
    -DOSQP_LIB_SUFFIX=$OSQP_LIB_SUFFIX \
    -B $BUILD_DIR \
    -S .
cmake --build $BUILD_DIR
cmake --install $BUILD_DIR
"""
end
