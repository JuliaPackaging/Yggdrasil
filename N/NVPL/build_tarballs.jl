# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "NVPL"
version = v"25.1.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://developer.download.nvidia.com/compute/nvpl/$(version)/local_installers/nvpl-linux-sbsa-$(version).tar.gz", "8116ff47e2be1911c28e7998acad16723be9c8b5d1f78c928c6eeadcc0e81b44")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/nvpl*-linux-sbsa-*

# license
install_license ./LICENSE

# compiled libraries
mkdir -p ${libdir}
mv ./lib/* ${libdir}

# header files
mkdir -p ${includedir}
mv ./include/* ${includedir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("aarch64", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libnvpl_blacs_ilp64_mpich", :libnvpl_blacs_ilp64_mpich),
    LibraryProduct("libnvpl_blacs_ilp64_openmpi3", :libnvpl_blacs_ilp64_openmpi3),
    LibraryProduct("libnvpl_blacs_ilp64_openmpi4", :libnvpl_blacs_ilp64_openmpi4),
    LibraryProduct("libnvpl_blacs_ilp64_openmpi5", :libnvpl_blacs_ilp64_openmpi5),
    LibraryProduct("libnvpl_blacs_lp64_mpich", :libnvpl_blacs_lp64_mpich),
    LibraryProduct("libnvpl_blacs_lp64_openmpi3", :libnvpl_blacs_lp64_openmpi3),
    LibraryProduct("libnvpl_blacs_lp64_openmpi4", :libnvpl_blacs_lp64_openmpi4),
    LibraryProduct("libnvpl_blacs_lp64_openmpi5", :libnvpl_blacs_lp64_openmpi5),
    LibraryProduct("libnvpl_blas_core", :libnvpl_blas_core),
    LibraryProduct("libnvpl_blas_ilp64_gomp", :libnvpl_blas_ilp64_gomp),
    LibraryProduct("libnvpl_blas_ilp64_seq", :libnvpl_blas_ilp64_seq),
    LibraryProduct("libnvpl_blas_lp64_gomp", :libnvpl_blas_lp64_gomp),
    LibraryProduct("libnvpl_blas_lp64_seq", :libnvpl_blas_lp64_seq),
    LibraryProduct("libnvpl_fftw", :libnvpl_fftw),
    LibraryProduct("libnvpl_lapack_core", :libnvpl_lapack_core),
    LibraryProduct("libnvpl_lapack_ilp64_gomp", :libnvpl_lapack_ilp64_gomp),
    LibraryProduct("libnvpl_lapack_ilp64_seq", :libnvpl_lapack_ilp64_seq),
    LibraryProduct("libnvpl_lapack_lp64_gomp", :libnvpl_lapack_lp64_gomp),
    LibraryProduct("libnvpl_lapack_lp64_seq", :libnvpl_lapack_lp64_seq),
    LibraryProduct("libnvpl_rand_mt", :libnvpl_rand_mt),
    LibraryProduct("libnvpl_rand", :libnvpl_rand),
    LibraryProduct("libnvpl_scalapack_ilp64", :libnvpl_scalapack_ilp64),
    LibraryProduct("libnvpl_scalapack_lp64", :libnvpl_scalapack_lp64),
    LibraryProduct("libnvpl_sparse", :libnvpl_sparse),
    LibraryProduct("libnvpl_tensor", :libnvpl_tensor),
    FileProduct("include/nvpl_blas.fi", :include_nvpl_blas_fi),
    FileProduct("include/nvpl_blas.h", :include_nvpl_blas_h),
    FileProduct("include/nvpl_blas_cblas.h", :include_nvpl_blas_cblas_h),
    FileProduct("include/nvpl_blas_config.h", :include_nvpl_blas_config_h),
    FileProduct("include/nvpl_blas_f77_blas.fi", :include_nvpl_blas_f77_blas_h),
    FileProduct("include/nvpl_blas_f77_blas.h", :include_nvpl_blas_f77_blas_h),
    FileProduct("include/nvpl_blas_service.fi", :include_nvpl_blas_service_h),
    FileProduct("include/nvpl_blas_service.h", :include_nvpl_blas_service_h),
    FileProduct("include/nvpl_blas_types.h", :include_nvpl_blas_types_h),
    FileProduct("include/nvpl_blas_version.h", :include_nvpl_blas_version_h),
    FileProduct("include/nvpl_lapack.h", :include_nvpl_lapack_h),
    FileProduct("include/nvpl_lapack_config.h", :include_nvpl_lapack_config_h),
    FileProduct("include/nvpl_lapack_service.h", :include_nvpl_lapack_service_h),
    FileProduct("include/nvpl_lapack_types.h", :include_nvpl_lapack_types_h),
    FileProduct("include/nvpl_lapack_version.h", :include_nvpl_lapack_version_h),
    FileProduct("include/nvpl_lapacke.h", :include_nvpl_lapacke_h),
    FileProduct("include/nvpl_fftw.h", :include_nvpl_fftw_h),
    FileProduct("include/nvpl_fftw3.f", :include_nvpl_fftw3_f),
    FileProduct("include/nvpl_fftw3.f03", :include_nvpl_fftw3_f03),
    FileProduct("include/nvpl_fft_version.h", :include_nvpl_fft_version_h),
    FileProduct("include/nvpl_fftw/fftw3.h", :include_nvpl_fftw_fftw3_h),
    FileProduct("include/nvpl_fftw/fftw3.f", :include_nvpl_fftw_fftw3_f),
    FileProduct("include/nvpl_fftw/fftw3.f03", :include_nvpl_fftw_fftw3_f03),
    FileProduct("include/nvpl_fftw/nvpl_fft_version.h", :include_nvpl_fftw_nvpl_fft_version_h),
    FileProduct("include/nvpl_rand.h", :include_nvpl_rand_h),
    FileProduct("include/nvpl_rand_version.h", :include_nvpl_rand_version_h),
    FileProduct("include/nvpl_scalapack.h", :include_nvpl_scalapack_h),
    FileProduct("include/nvpl_scalapack_api_c.h", :include_nvpl_scalapack_api_c_h),
    FileProduct("include/nvpl_scalapack_blacs.h", :include_nvpl_scalapack_blacs_h),
    FileProduct("include/nvpl_scalapack_cblacs.h", :include_nvpl_scalapack_cblacs_h),
    FileProduct("include/nvpl_scalapack_pblas.h", :include_nvpl_scalapack_pblas_h),
    FileProduct("include/nvpl_scalapack_types.h", :include_nvpl_scalapack_types_h),
    FileProduct("include/nvpl_scalapack_verbose.h", :include_nvpl_scalapack_verbose_h),
    FileProduct("include/nvpl_scalapack_version.h", :include_nvpl_scalapack_version_h),
    FileProduct("include/nvpl_sparse.h", :include_nvpl_sparse_h),
    FileProduct("include/nvpl_tensor.h", :include_nvpl_tensor_h),
    FileProduct("include/nvpl_tensor/types.h", :include_nvpl_tensor_types_h),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
