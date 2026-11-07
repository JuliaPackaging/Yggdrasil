#ifndef ASTRA_JULIA_C_API_H
#define ASTRA_JULIA_C_API_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Minimal C ABI for Julia native bindings.
// All buffers are borrowed and must stay alive for the duration of the call.
int astra_julia_fp2d_parallel_line_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    float* volume,
    float* sinogram);

int astra_julia_cuda_fp2d_parallel_line_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    const float* volume,
    float* sinogram,
    int detector_supersampling,
    int gpu_index);

int astra_julia_bp2d_parallel_line_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    const float* sinogram,
    float* volume);

int astra_julia_cuda_bp2d_parallel_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    const float* sinogram,
    float* volume,
    int detector_supersampling,
    int pixel_supersampling,
    int gpu_index);

int astra_julia_fp2d_parallel_vec_line_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    float* volume,
    float* sinogram);

int astra_julia_cuda_fp2d_parallel_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* volume,
    float* sinogram,
    int detector_supersampling,
    int gpu_index);

int astra_julia_bp2d_parallel_vec_line_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume);

int astra_julia_cuda_bp2d_parallel_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int detector_supersampling,
    int pixel_supersampling,
    int gpu_index);

int astra_julia_fp2d_fanflat_line_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    float origin_source_distance,
    float origin_detector_distance,
    const float* angles,
    float* volume,
    float* sinogram);

int astra_julia_bp2d_fanflat_line_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    float origin_source_distance,
    float origin_detector_distance,
    const float* angles,
    const float* sinogram,
    float* volume);

int astra_julia_cuda_fp2d_fanflat_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    float origin_source_distance,
    float origin_detector_distance,
    const float* angles,
    const float* volume,
    float* sinogram,
    int detector_supersampling,
    int gpu_index);

int astra_julia_cuda_bp2d_fanflat_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    float origin_source_distance,
    float origin_detector_distance,
    const float* angles,
    const float* sinogram,
    float* volume,
    int detector_supersampling,
    int pixel_supersampling,
    int gpu_index);

int astra_julia_fp2d_fanflat_vec_line_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    float* volume,
    float* sinogram);

int astra_julia_cuda_fp2d_fanflat_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* volume,
    float* sinogram,
    int detector_supersampling,
    int gpu_index);

int astra_julia_bp2d_fanflat_vec_line_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume);

int astra_julia_cuda_bp2d_fanflat_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int detector_supersampling,
    int pixel_supersampling,
    int gpu_index);

int astra_julia_fbp2d_parallel_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    const float* sinogram,
    float* volume,
    int filter_type,
    const float* custom_filter,
    int custom_filter_width,
    int custom_filter_height,
    float filter_d,
    float filter_parameter);

int astra_julia_cuda_fbp2d_parallel_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    const float* sinogram,
    float* volume,
    int filter_type,
    const float* custom_filter,
    int custom_filter_width,
    int custom_filter_height,
    float filter_d,
    float filter_parameter,
    int gpu_index);

int astra_julia_cuda_fbp2d_parallel_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int filter_type,
    const float* custom_filter,
    int custom_filter_width,
    int custom_filter_height,
    float filter_d,
    float filter_parameter,
    int gpu_index);

int astra_julia_cuda_fbp2d_fanflat_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    float origin_source_distance,
    float origin_detector_distance,
    const float* angles,
    const float* sinogram,
    float* volume,
    int filter_type,
    const float* custom_filter,
    int custom_filter_width,
    int custom_filter_height,
    float filter_d,
    float filter_parameter,
    int short_scan,
    int gpu_index);

int astra_julia_cuda_fbp2d_fanflat_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int filter_type,
    const float* custom_filter,
    int custom_filter_width,
    int custom_filter_height,
    float filter_d,
    float filter_parameter,
    int short_scan,
    int gpu_index);

int astra_julia_cuda_sart2d_parallel_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    const float* reconstruction_mask,
    float* residual_norm,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint,
    int projection_order_mode,
    const int* projection_order,
    int projection_order_length,
    int detector_supersampling,
    int pixel_supersampling,
    int gpu_index);

int astra_julia_cuda_sirt2d_parallel_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    float* residual_norm,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint,
    int detector_supersampling,
    int pixel_supersampling,
    int gpu_index);

int astra_julia_cuda_sart2d_parallel_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    const float* reconstruction_mask,
    float* residual_norm,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint,
    int projection_order_mode,
    const int* projection_order,
    int projection_order_length,
    int detector_supersampling,
    int pixel_supersampling,
    int gpu_index);

int astra_julia_cuda_sirt2d_parallel_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    float* residual_norm,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint,
    int detector_supersampling,
    int pixel_supersampling,
    int gpu_index);

int astra_julia_cuda_sart2d_fanflat_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    float origin_source_distance,
    float origin_detector_distance,
    const float* angles,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    const float* reconstruction_mask,
    float* residual_norm,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint,
    int projection_order_mode,
    const int* projection_order,
    int projection_order_length,
    int detector_supersampling,
    int pixel_supersampling,
    int gpu_index);

int astra_julia_cuda_sirt2d_fanflat_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    float origin_source_distance,
    float origin_detector_distance,
    const float* angles,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    float* residual_norm,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint,
    int detector_supersampling,
    int pixel_supersampling,
    int gpu_index);

int astra_julia_cuda_sart2d_fanflat_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    const float* reconstruction_mask,
    float* residual_norm,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint,
    int projection_order_mode,
    const int* projection_order,
    int projection_order_length,
    int detector_supersampling,
    int pixel_supersampling,
    int gpu_index);

int astra_julia_cuda_sirt2d_fanflat_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    float* residual_norm,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint,
    int detector_supersampling,
    int pixel_supersampling,
    int gpu_index);

int astra_julia_cuda_cgls2d_parallel_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    const float* sinogram,
    float* volume,
    int iterations,
    const float* reconstruction_mask,
    float* residual_norm,
    int detector_supersampling,
    int pixel_supersampling,
    int gpu_index);

int astra_julia_cuda_em2d_parallel_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    const float* sinogram,
    float* volume,
    int iterations,
    float* residual_norm,
    int detector_supersampling,
    int pixel_supersampling,
    int gpu_index);

int astra_julia_cuda_cgls2d_parallel_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int iterations,
    const float* reconstruction_mask,
    float* residual_norm,
    int detector_supersampling,
    int pixel_supersampling,
    int gpu_index);

int astra_julia_cuda_cgls2d_fanflat_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    float origin_source_distance,
    float origin_detector_distance,
    const float* angles,
    const float* sinogram,
    float* volume,
    int iterations,
    const float* reconstruction_mask,
    float* residual_norm,
    int detector_supersampling,
    int pixel_supersampling,
    int gpu_index);

int astra_julia_cuda_cgls2d_fanflat_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int iterations,
    const float* reconstruction_mask,
    float* residual_norm,
    int detector_supersampling,
    int pixel_supersampling,
    int gpu_index);

int astra_julia_cuda_fp3d_parallel_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    float detector_spacing_u,
    float detector_spacing_v,
    const float* angles,
    const float* volume,
    float* sinogram,
    int gpu_index);

int astra_julia_cuda_bp3d_parallel_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    float detector_spacing_u,
    float detector_spacing_v,
    const float* angles,
    const float* sinogram,
    float* volume,
    int voxel_supersampling,
    int gpu_index);

int astra_julia_cuda_fp3d_parallel_vec_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    const float* vectors,
    const float* volume,
    float* sinogram,
    int gpu_index);

int astra_julia_cuda_bp3d_parallel_vec_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int voxel_supersampling,
    int gpu_index);

int astra_julia_cuda_fp3d_cone_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    float detector_spacing_u,
    float detector_spacing_v,
    float origin_source_distance,
    float origin_detector_distance,
    const float* angles,
    const float* volume,
    float* sinogram,
    int detector_supersampling,
    int gpu_index);

int astra_julia_cuda_bp3d_cone_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    float detector_spacing_u,
    float detector_spacing_v,
    float origin_source_distance,
    float origin_detector_distance,
    const float* angles,
    const float* sinogram,
    float* volume,
    int voxel_supersampling,
    int gpu_index);

int astra_julia_cuda_fp3d_cone_vec_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    const float* vectors,
    const float* volume,
    float* sinogram,
    int detector_supersampling,
    int gpu_index);

int astra_julia_cuda_bp3d_cone_vec_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int voxel_supersampling,
    int gpu_index);

int astra_julia_cuda_fp3d_cyl_cone_vec_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    const float* vectors,
    const float* volume,
    float* sinogram,
    int gpu_index);

int astra_julia_cuda_bp3d_cyl_cone_vec_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int voxel_supersampling,
    int gpu_index);

int astra_julia_cuda_sirt3d_parallel_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    float detector_spacing_u,
    float detector_spacing_v,
    const float* angles,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    float* residual_norm,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint,
    int voxel_supersampling,
    int detector_supersampling,
    int gpu_index);

int astra_julia_cuda_sirt3d_parallel_vec_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    float* residual_norm,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint,
    int voxel_supersampling,
    int detector_supersampling,
    int gpu_index);

int astra_julia_cuda_sirt3d_cone_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    float detector_spacing_u,
    float detector_spacing_v,
    float origin_source_distance,
    float origin_detector_distance,
    const float* angles,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    float* residual_norm,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint,
    int voxel_supersampling,
    int detector_supersampling,
    int gpu_index);

int astra_julia_cuda_sirt3d_cone_vec_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    float* residual_norm,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint,
    int voxel_supersampling,
    int detector_supersampling,
    int gpu_index);

int astra_julia_cuda_sirt3d_cyl_cone_vec_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    float* residual_norm,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint,
    int voxel_supersampling,
    int detector_supersampling,
    int gpu_index);

int astra_julia_cuda_cgls3d_parallel_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    float detector_spacing_u,
    float detector_spacing_v,
    const float* angles,
    const float* sinogram,
    float* volume,
    int iterations,
    const float* reconstruction_mask,
    float* residual_norm,
    int voxel_supersampling,
    int detector_supersampling,
    int gpu_index);

int astra_julia_cuda_cgls3d_parallel_vec_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int iterations,
    const float* reconstruction_mask,
    float* residual_norm,
    int voxel_supersampling,
    int detector_supersampling,
    int gpu_index);

int astra_julia_cuda_cgls3d_cone_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    float detector_spacing_u,
    float detector_spacing_v,
    float origin_source_distance,
    float origin_detector_distance,
    const float* angles,
    const float* sinogram,
    float* volume,
    int iterations,
    const float* reconstruction_mask,
    float* residual_norm,
    int voxel_supersampling,
    int detector_supersampling,
    int gpu_index);

int astra_julia_cuda_cgls3d_cone_vec_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int iterations,
    const float* reconstruction_mask,
    float* residual_norm,
    int voxel_supersampling,
    int detector_supersampling,
    int gpu_index);

int astra_julia_cuda_cgls3d_cyl_cone_vec_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int iterations,
    const float* reconstruction_mask,
    float* residual_norm,
    int voxel_supersampling,
    int detector_supersampling,
    int gpu_index);

int astra_julia_cuda_fdk3d_cone_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    float detector_spacing_u,
    float detector_spacing_v,
    float origin_source_distance,
    float origin_detector_distance,
    const float* angles,
    const float* sinogram,
    float* volume,
    int filter_type,
    const float* custom_filter,
    int custom_filter_width,
    int custom_filter_height,
    float filter_d,
    float filter_parameter,
    int short_scan,
    int voxel_supersampling,
    int gpu_index);

int astra_julia_cuda_fdk3d_cone_vec_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int filter_type,
    const float* custom_filter,
    int custom_filter_width,
    int custom_filter_height,
    float filter_d,
    float filter_parameter,
    int short_scan,
    int voxel_supersampling,
    int gpu_index);

int astra_julia_has_cuda(void);
int astra_julia_has_feature(const char* feature);
int astra_julia_get_gpu_count(void);
const char* astra_julia_get_gpu_info(int gpu_index);
int astra_julia_set_gpu_index(int gpu_index);
int astra_julia_get_gpu_index(void);

int astra_julia_fp2d_parallel_linear_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    const float* volume,
    float* sinogram);

int astra_julia_bp2d_parallel_linear_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    const float* sinogram,
    float* volume);

int astra_julia_fp2d_parallel_vec_linear_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* volume,
    float* sinogram);

int astra_julia_bp2d_parallel_vec_linear_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume);

int astra_julia_fp2d_parallel_strip_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    const float* volume,
    float* sinogram);

int astra_julia_bp2d_parallel_strip_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    const float* sinogram,
    float* volume);

int astra_julia_fp2d_parallel_vec_strip_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* volume,
    float* sinogram);

int astra_julia_bp2d_parallel_vec_strip_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume);

int astra_julia_fp2d_fanflat_strip_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    float origin_source_distance,
    float origin_detector_distance,
    const float* angles,
    const float* volume,
    float* sinogram);

int astra_julia_bp2d_fanflat_strip_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    float origin_source_distance,
    float origin_detector_distance,
    const float* angles,
    const float* sinogram,
    float* volume);

int astra_julia_fp2d_parallel_distance_driven_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    const float* volume,
    float* sinogram);

int astra_julia_bp2d_parallel_distance_driven_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    const float* sinogram,
    float* volume);

int astra_julia_fp2d_parallel_vec_distance_driven_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* volume,
    float* sinogram);

int astra_julia_bp2d_parallel_vec_distance_driven_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume);

int astra_julia_sirt2d_parallel_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    int projector_kernel,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint);

int astra_julia_sirt2d_parallel_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    int projector_kernel,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint);

int astra_julia_sirt2d_fanflat_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    float origin_source_distance,
    float origin_detector_distance,
    const float* angles,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    int projector_kernel,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint);

int astra_julia_sirt2d_fanflat_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    int projector_kernel,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint);

int astra_julia_sart2d_parallel_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    int projection_order_mode,
    const int* projection_order,
    int projection_order_length,
    int projector_kernel,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint);

int astra_julia_sart2d_parallel_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    int projection_order_mode,
    const int* projection_order,
    int projection_order_length,
    int projector_kernel,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint);

int astra_julia_sart2d_fanflat_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    float origin_source_distance,
    float origin_detector_distance,
    const float* angles,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    int projection_order_mode,
    const int* projection_order,
    int projection_order_length,
    int projector_kernel,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint);

int astra_julia_sart2d_fanflat_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    int projection_order_mode,
    const int* projection_order,
    int projection_order_length,
    int projector_kernel,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint);

int astra_julia_cgls2d_parallel_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    const float* sinogram,
    float* volume,
    int iterations,
    int projector_kernel,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint);

int astra_julia_cgls2d_parallel_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int iterations,
    int projector_kernel,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint);

int astra_julia_cgls2d_fanflat_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    float origin_source_distance,
    float origin_detector_distance,
    const float* angles,
    const float* sinogram,
    float* volume,
    int iterations,
    int projector_kernel,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint);

int astra_julia_cgls2d_fanflat_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int iterations,
    int projector_kernel,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint);

int astra_julia_art2d_parallel_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    int projector_kernel,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint);

int astra_julia_art2d_parallel_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    int projector_kernel,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint);

int astra_julia_art2d_fanflat_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    float origin_source_distance,
    float origin_detector_distance,
    const float* angles,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    int projector_kernel,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint);

int astra_julia_art2d_fanflat_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    int projector_kernel,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint);

int astra_julia_fp2d_sparse_matrix_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    uint64_t nnz,
    const uint64_t* row_starts,
    const uint32_t* col_indices,
    const float* values,
    const float* volume,
    float* sinogram);

int astra_julia_bp2d_sparse_matrix_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    uint64_t nnz,
    const uint64_t* row_starts,
    const uint32_t* col_indices,
    const float* values,
    const float* sinogram,
    float* volume);

int astra_julia_sirt2d_sparse_matrix_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    uint64_t nnz,
    const uint64_t* row_starts,
    const uint32_t* col_indices,
    const float* values,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint);

int astra_julia_sart2d_sparse_matrix_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    uint64_t nnz,
    const uint64_t* row_starts,
    const uint32_t* col_indices,
    const float* values,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    int projection_order_mode,
    const int* projection_order,
    int projection_order_length,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint);

int astra_julia_cgls2d_sparse_matrix_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    uint64_t nnz,
    const uint64_t* row_starts,
    const uint32_t* col_indices,
    const float* values,
    const float* sinogram,
    float* volume,
    int iterations,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint);

int astra_julia_art2d_sparse_matrix_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    uint64_t nnz,
    const uint64_t* row_starts,
    const uint32_t* col_indices,
    const float* values,
    const float* sinogram,
    float* volume,
    int iterations,
    float relaxation,
    const float* reconstruction_mask,
    const float* sinogram_mask,
    int use_min_constraint,
    float min_constraint,
    int use_max_constraint,
    float max_constraint);

int astra_julia_set_volume_window_2d(float min_x, float min_y, float max_x, float max_y);
int astra_julia_clear_volume_window_2d(void);
int astra_julia_get_volume_window_2d(float* window_out);

int astra_julia_set_volume_window_3d(float min_x, float min_y, float min_z, float max_x, float max_y, float max_z);
int astra_julia_clear_volume_window_3d(void);
int astra_julia_get_volume_window_3d(float* window_out);

int astra_julia_cuda_dart_mask_2d_f32(
    float* mask,
    const float* segmentation,
    uint32_t conn,
    uint32_t radius,
    uint32_t threshold,
    uint32_t width,
    uint32_t height,
    int gpu_index);

int astra_julia_cuda_dart_smoothing_2d_f32(
    float* out,
    const float* in,
    float b,
    uint32_t radius,
    uint32_t width,
    uint32_t height,
    int gpu_index);

int astra_julia_cuda_roi_select_2d_f32(
    float* out,
    float radius,
    uint32_t width,
    uint32_t height,
    int gpu_index);

int astra_julia_cuda_dart_mask_3d_f32(
    float* mask,
    const float* segmentation,
    uint32_t conn,
    uint32_t radius,
    uint32_t threshold,
    uint32_t width,
    uint32_t height,
    uint32_t depth,
    int gpu_index);

int astra_julia_cuda_dart_smoothing_3d_f32(
    float* out,
    const float* in,
    float b,
    uint32_t radius,
    uint32_t width,
    uint32_t height,
    uint32_t depth,
    int gpu_index);

typedef struct {
    float* data;
    int32_t grid_col_count;
    int32_t grid_row_count;
    int32_t grid_slice_count;
    float min_x;
    float max_x;
    float min_y;
    float max_y;
    float min_z;
    float max_z;
} astra_julia_volume_part_t;

typedef struct {
    float* data;
    int32_t geom_type; // 0: Parallel3D, 1: ParallelVec3D, 2: Cone3D, 3: ConeVec3D, 4: CylConeVec3D
    int32_t proj_count;
    int32_t det_row_count;
    int32_t det_col_count;
    float det_width;
    float det_height;
    float src_origin;
    float origin_det;
    float cyl_radius;
    const float* angles;
    const float* vectors;
} astra_julia_projection_part_t;

int astra_julia_cuda_composite_fp3d_f32(
    int num_volumes,
    const astra_julia_volume_part_t* volumes,
    int num_projections,
    const astra_julia_projection_part_t* projections,
    int mode,
    int gpu_index);

int astra_julia_cuda_composite_bp3d_f32(
    int num_volumes,
    const astra_julia_volume_part_t* volumes,
    int num_projections,
    const astra_julia_projection_part_t* projections,
    int mode,
    int gpu_index);

int astra_julia_project_point_3d(
    const astra_julia_projection_part_t* proj,
    double x, double y, double z,
    int angle_idx,
    double* out_u, double* out_v);

int astra_julia_projected_bbox_3d(
    const astra_julia_projection_part_t* proj,
    double min_x, double max_x,
    double min_y, double max_y,
    double min_z, double max_z,
    int angle_idx,
    double* out_min_u, double* out_max_u,
    double* out_min_v, double* out_max_v);

const char* astra_julia_last_error(void);

#ifdef __cplusplus
}
#endif

#endif
