# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PoseLib"
# Upstream PoseLib has no release after v2.0.5; the pinned commit below is
# v2.0.5-30-ga69263d (its VERSION.txt already reads the unreleased 3.0.0).
# v2.0.6 marks "after 2.0.5, before upstream's next release" and cannot
# collide with it.
version = v"2.0.6"

# 1. Upstream PoseLib (BSD-3-Clause), built as a static library.
# 2. `julia_wrapper.cpp` (MIT, from PoseLib.jl): the flat C ABI that PoseLib.jl
#    `ccall`s, compiled into the one shared library this JLL ships.
#    Until https://github.com/VisualGeometryToolkit/PoseLib.jl is public, the
#    wrapper and PoseLib.jl's LICENSE travel in `bundled/`, laid out as in
#    that repository (byte-identical copies; PoseLib.jl's test suite checks
#    it) and unpacked to the same `srcdir/PoseLib.jl`. Once a release is tagged
#    there, swap the DirectorySource for the commented GitSource (the commit of
#    that tag) and delete `bundled/`; the script does not change.
sources = [
    GitSource("https://github.com/PoseLib/PoseLib.git",
              "a69263d5d824b5de11e48756f33f6e8ebb231f0c"),
    DirectorySource("./bundled"; target = "PoseLib.jl"),
    # GitSource("https://github.com/VisualGeometryToolkit/PoseLib.jl.git",
    #           "<commit of the release tag>"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/PoseLib

# Upstream compiles with -Werror; warnings differ across the cross compilers.
sed -i 's/ -Werror / /' CMakeLists.txt

# Static PoseLib into a private staging prefix: neither libPoseLib.a nor its
# headers are shipped, only the wrapper library that links it.
cmake -B build -S . \
    -DCMAKE_INSTALL_PREFIX=${WORKSPACE}/poselib \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
cmake --build build --parallel ${nproc}
cmake --install build

# The wrapper, with the flags PoseLib.jl's former from-source build used.
mkdir -p ${libdir}
${CXX} -std=c++17 -O3 -fPIC -shared \
    -I${WORKSPACE}/poselib/include \
    -I${includedir}/eigen3 \
    ${WORKSPACE}/srcdir/PoseLib.jl/wrapper/julia_wrapper.cpp \
    -o ${libdir}/libposelib_jl.${dlext} \
    -L${WORKSPACE}/poselib/lib -lPoseLib

# Licenses of everything compiled in; both projects name theirs LICENSE.
cp ${WORKSPACE}/srcdir/PoseLib/LICENSE ${WORKSPACE}/LICENSE.PoseLib           # BSD-3-Clause
cp ${WORKSPACE}/srcdir/PoseLib.jl/LICENSE ${WORKSPACE}/LICENSE.PoseLib.jl     # MIT, the wrapper
install_license ${WORKSPACE}/LICENSE.PoseLib ${WORKSPACE}/LICENSE.PoseLib.jl
# Eigen's dense headers: MPL-2.0, with a few files under BSD (Half.h) and
# Apache-2.0 (BFloat16.h). Its GPL/LGPL/MINPACK texts cover only unsupported/.
for f in MPL2 BSD APACHE README; do
    install_license ${prefix}/share/licenses/Eigen/COPYING.${f}
done
"""

platforms = expand_cxxstring_abis(supported_platforms())

products = [
    LibraryProduct("libposelib_jl", :libposelib_jl),
]

dependencies = [
    # Header-only; pinned to the Eigen PoseLib.jl's results were produced with.
    BuildDependency(PackageSpec(name = "Eigen_jll", version = v"3.4.0+0")),
    # libstdc++ / libgcc_s (FreeBSD's libc++ build still links libgcc_s; Apple's does not).
    Dependency("CompilerSupportLibraries_jll"; platforms = filter(!Sys.isapple, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.6", preferred_gcc_version = v"8")
