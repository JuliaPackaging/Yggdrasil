# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "libcrystfel"
version = v"0.12.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gitlab.desy.de/thomas.white/crystfel/-/archive/$(version)/crystfel-$(version).tar.gz", "552cb274de8b3b930c7a574d82e25ae44aeae23e39882d33617bbc6cfdc64d7c"),
    GitSource("https://gitlab.desy.de/thomas.white/fdip.git", "631792e90ed2c3e226dce77bf97917305293ac66")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd crystfel-*
mv ../fdip subprojects/fdip

LINK_ARGS=''

# Allow undefined symbols in linked libraries. Needed on some platforms because
# our HDF5 is built with MPI support but we don't have MPI as a dependency.
if [[ ${target} != *-apple-* ]]; then
   LINK_ARGS='-Wl,--allow-shlib-undefined'
fi

# Handle argp on glibc/musl
if [[ ${target} == *-musl* || ${target} == *-apple-* ]]; then
    LINK_ARGS="${LINK_ARGS} -largp"
else
    # Ugly hack: we need argp-standalone to build with musl, but when installed
    # alongside glibc it causes compilation errors. So when not on musl we
    # delete the argp.h header so it won't be used.
    rm -f ${includedir}/argp.h
fi

# --wrap-mode: Don't download other sources automatically
meson setup \
      --cross-file=${MESON_TARGET_TOOLCHAIN} \
      --buildtype=release \
      --wrap-mode=nodownload \
      -Dcpp_link_args="${LINK_ARGS}" \
      build

meson compile -C build
meson install -C build

install_license COPYING
"""

sources, script = require_macos_sdk("10.13", sources, script)

# - Windows is not supported because we need forkpty() (and probably other
#   things).
# - Freebsd is not supported because crystfel doesn't recognize libutil.h to get
#   forkpty().
platforms = filter(p -> Sys.islinux(p) || Sys.isapple(p), supported_platforms())
platforms, platform_dependencies = MPI.augment_platforms(platforms)

# The products that we will ensure are always built
products = [
    FileProduct("include/crystfel/reflist.h", :reflist_h),
    FileProduct("include/crystfel/symmetry.h", :symmetry_h),
    FileProduct("include/crystfel/cell.h", :cell_h),
    FileProduct("include/crystfel/reflist-utils.h", :reflist_utils_h),
    FileProduct("include/crystfel/thread-pool.h", :thread_pool_h),
    FileProduct("include/crystfel/utils.h", :utils_h),
    FileProduct("include/crystfel/geometry.h", :geometry_h),
    FileProduct("include/crystfel/peaks.h", :peaks_h),
    FileProduct("include/crystfel/stream.h", :stream_h),
    FileProduct("include/crystfel/index.h", :index_h),
    FileProduct("include/crystfel/image.h", :image_h),
    FileProduct("include/crystfel/filters.h", :filters_h),
    FileProduct("include/crystfel/cell-utils.h", :cell_utils_h),
    FileProduct("include/crystfel/integer_matrix.h", :integer_matrix_h),
    FileProduct("include/crystfel/crystal.h", :crystal_h),
    FileProduct("include/crystfel/predict-refine.h", :predict_refine_h),
    FileProduct("include/crystfel/integration.h", :integration_h),
    FileProduct("include/crystfel/rational.h", :rational_h),
    FileProduct("include/crystfel/spectrum.h", :spectrum_h),
    FileProduct("include/crystfel/datatemplate.h", :datatemplate_h),
    FileProduct("include/crystfel/colscale.h", :colscale_h),
    FileProduct("include/crystfel/detgeom.h", :detgeom_h),
    FileProduct("include/crystfel/fom.h", :fom_h),
    FileProduct("include/crystfel/crystfel-mille.h", :crystfel_mille_h),
    LibraryProduct("libcrystfel", :libcrystfel),
    ExecutableProduct("indexamajig", :indexamajig)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Eigen is required for fdip. It's a header-only library so we can get away
    # with it only being a build dependency.
    BuildDependency("Eigen_jll"),
    Dependency("HDF5_jll"; compat="~2.1"),
    Dependency("GSL_jll"; compat="~2.8.1"),
    Dependency("argp_standalone_jll")
]
append!(dependencies, platform_dependencies)

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
    """

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block,
               julia_compat="1.10",
               # Need this to find the linker on macos
               clang_use_lld=false,
               # GCC version required by HDF5
               preferred_gcc_version=v"12")
