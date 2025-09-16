# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PCL"
version = v"1.15.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/PointCloudLibrary/pcl/releases/download/pcl-$version/source.tar.gz",
                  "fb79d085b08b8335f43ee4cacf4daa2624bb2c411e9243efa6a92c077273840a"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pcl*

# Patch to simplify CMake checks
atomic_patch -p1 ../patches/0001-Replace-run-checks-with-compile-checks.patch

#see https://github.com/PointCloudLibrary/pcl/pull/4695 for -DPCL_WARNINGS_ARE_ERRORS flag

cmake_extra_args=()

if [[ "${target}" == *-mingw* ]]; then
    cmake_extra_args+=(
        -DPCL_BUILD_WITH_BOOST_DYNAMIC_LINKING_WIN32=ON
        -DBoost_DIR=${libdir}/cmake/Boost-1.87.0/)
fi

cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DWITH_VTK=OFF \
    -DWITH_LIBUSB=OFF \
    -DWITH_QT=OFF \
    -DWITH_CUDA=OFF \
    -DWITH_QHULL=OFF \
    -DWITH_OPENGL=OFF \
    -DWITH_PCAP=OFF \
    -DPCL_WARNINGS_ARE_ERRORS=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=14 \
    "${cmake_extra_args[@]}"

cmake --build build -j${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())


# The products that we will ensure are always built
products = [

    ExecutableProduct("pcl_add_gaussian_noise", :pcl_add_gaussian_noise),
    ExecutableProduct("pcl_bilateral_upsampling", :pcl_bilateral_upsampling),
    ExecutableProduct("pcl_boundary_estimation", :pcl_boundary_estimation),
    ExecutableProduct("pcl_cluster_extraction", :pcl_cluster_extraction),
    ExecutableProduct("pcl_compute_cloud_error", :pcl_compute_cloud_error),
    ExecutableProduct("pcl_compute_hausdorff", :pcl_compute_hausdorff),
    ExecutableProduct("pcl_concatenate_points_pcd", :pcl_concatenate_points_pcd),
    ExecutableProduct("pcl_convert_pcd_ascii_binary", :pcl_convert_pcd_ascii_binary),
    ExecutableProduct("pcl_crf_segmentation", :pcl_crf_segmentation),
    ExecutableProduct("pcl_demean_cloud", :pcl_demean_cloud),
    ExecutableProduct("pcl_elch", :pcl_elch),
    ExecutableProduct("pcl_extract_feature", :pcl_extract_feature),
    ExecutableProduct("pcl_fast_bilateral_filter", :pcl_fast_bilateral_filter),
    ExecutableProduct("pcl_fpfh_estimation", :pcl_fpfh_estimation),
    ExecutableProduct("pcl_generate", :pcl_generate),
    ExecutableProduct("pcl_gp3_surface", :pcl_gp3_surface),
    ExecutableProduct("pcl_grid_min", :pcl_grid_min),
    ExecutableProduct("pcl_hdl_grabber", :pcl_hdl_grabber),
    ExecutableProduct("pcl_icp", :pcl_icp),
    ExecutableProduct("pcl_icp2d", :pcl_icp2d),
    ExecutableProduct("pcl_linemod_detection", :pcl_linemod_detection),
    ExecutableProduct("pcl_local_max", :pcl_local_max),
    ExecutableProduct("pcl_lum", :pcl_lum),
    ExecutableProduct("pcl_marching_cubes_reconstruction", :pcl_marching_cubes_reconstruction),
    ExecutableProduct("pcl_match_linemod_template", :pcl_match_linemod_template),
    ExecutableProduct("pcl_mls_smoothing", :pcl_mls_smoothing),
    ExecutableProduct("pcl_morph", :pcl_morph),
    ExecutableProduct("pcl_ndt2d", :pcl_ndt2d),
    ExecutableProduct("pcl_ndt3d", :pcl_ndt3d),
    ExecutableProduct("pcl_normal_estimation", :pcl_normal_estimation),
    ExecutableProduct("pcl_outlier_removal", :pcl_outlier_removal),
    ExecutableProduct("pcl_passthrough_filter", :pcl_passthrough_filter),
    ExecutableProduct("pcl_pcd2ply", :pcl_pcd2ply),
    ExecutableProduct("pcl_pcd2vtk", :pcl_pcd2vtk),
    ExecutableProduct("pcl_pcd_change_viewpoint", :pcl_pcd_change_viewpoint),
    ExecutableProduct("pcl_pcd_convert_NaN_nan", :pcl_pcd_convert_NaN_nan),
    ExecutableProduct("pcl_pcd_introduce_nan", :pcl_pcd_introduce_nan),
    ExecutableProduct("pcl_pclzf2pcd", :pcl_pclzf2pcd),
    ExecutableProduct("pcl_plane_projection", :pcl_plane_projection),
    ExecutableProduct("pcl_ply2obj", :pcl_ply2obj),
    ExecutableProduct("pcl_ply2pcd", :pcl_ply2pcd),
    ExecutableProduct("pcl_ply2ply", :pcl_ply2ply),
    ExecutableProduct("pcl_ply2raw", :pcl_ply2raw),
    ExecutableProduct("pcl_plyheader", :pcl_plyheader),
    ExecutableProduct("pcl_poisson_reconstruction", :pcl_poisson_reconstruction),
    ExecutableProduct("pcl_progressive_morphological_filter", :pcl_progressive_morphological_filter),
    ExecutableProduct("pcl_radius_filter", :pcl_radius_filter),
    ExecutableProduct("pcl_sac_segmentation_plane", :pcl_sac_segmentation_plane),
    ExecutableProduct("pcl_spin_estimation", :pcl_spin_estimation),
    ExecutableProduct("pcl_train_linemod_template", :pcl_train_linemod_template),
    ExecutableProduct("pcl_train_unary_classifier", :pcl_train_unary_classifier),
    ExecutableProduct("pcl_transform_from_viewpoint", :pcl_transform_from_viewpoint),
    ExecutableProduct("pcl_transform_point_cloud", :pcl_transform_point_cloud),
    ExecutableProduct("pcl_unary_classifier_segment", :pcl_unary_classifier_segment),
    ExecutableProduct("pcl_uniform_sampling", :pcl_uniform_sampling),
    ExecutableProduct("pcl_vfh_estimation", :pcl_vfh_estimation),
    ExecutableProduct("pcl_voxel_grid", :pcl_voxel_grid),
    ExecutableProduct("pcl_xyz2pcd", :pcl_xyz2pcd),

    LibraryProduct("libpcl_common", :libpcl_common),
    LibraryProduct("libpcl_features", :libpcl_features),
    LibraryProduct("libpcl_filters", :libpcl_filters),
    LibraryProduct("libpcl_io_ply", :libpcl_io_ply),
    LibraryProduct("libpcl_io", :libpcl_io),
    LibraryProduct("libpcl_kdtree", :libpcl_kdtree),
    LibraryProduct("libpcl_keypoints", :libpcl_keypoints),
    LibraryProduct("libpcl_ml", :libpcl_ml),
    LibraryProduct("libpcl_octree", :libpcl_octree),
    LibraryProduct("libpcl_recognition", :libpcl_recognition),
    LibraryProduct("libpcl_registration", :libpcl_registration),
    LibraryProduct("libpcl_sample_consensus", :libpcl_sample_consensus),
    LibraryProduct("libpcl_search", :libpcl_search),
    LibraryProduct("libpcl_segmentation", :libpcl_segmentation),
    LibraryProduct("libpcl_stereo", :libpcl_stereo),
    LibraryProduct("libpcl_surface", :libpcl_surface),
    LibraryProduct("libpcl_tracking", :libpcl_tracking),

]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms))
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms))
    Dependency(PackageSpec(name="FLANN_jll", uuid="48b6455b-4cf5-590d-a543-2d733c79e793"))
    Dependency(PackageSpec(name="boost_jll", uuid="28df3c45-c428-5900-9ff8-a3135698ca75"); compat="=1.87.0")
    BuildDependency(PackageSpec(name="Eigen_jll", uuid="bc6bbf8a-a594-5541-9c57-10b0d0312c70"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.10", preferred_gcc_version = v"11.1")
