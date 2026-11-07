#ifndef TIGRE_JULIA_SHIM_H
#define TIGRE_JULIA_SHIM_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

enum TigreJuliaMode {
    TIGRE_JULIA_MODE_CONE = 0,
    TIGRE_JULIA_MODE_PARALLEL = 1
};

enum TigreJuliaProjectionType {
    TIGRE_JULIA_PROJECTION_SIDDON = 0,
    TIGRE_JULIA_PROJECTION_INTERPOLATED = 1
};

enum TigreJuliaBackprojectionType {
    TIGRE_JULIA_BACKPROJECTION_FDK = 0,
    TIGRE_JULIA_BACKPROJECTION_MATCHED = 1
};

enum TigreJuliaStatus {
    TIGRE_JULIA_STATUS_SUCCESS = 0,
    TIGRE_JULIA_STATUS_INVALID_ARGUMENT = 64,
    TIGRE_JULIA_STATUS_RUNTIME_ERROR = 65
};

typedef struct TigreJuliaGeometry {
    int nVoxelX;
    int nVoxelY;
    int nVoxelZ;
    float sVoxelX;
    float sVoxelY;
    float sVoxelZ;
    float dVoxelX;
    float dVoxelY;
    float dVoxelZ;
    int nDetecU;
    int nDetecV;
    float sDetecU;
    float sDetecV;
    float dDetecU;
    float dDetecV;
    const float* offOrigX;
    const float* offOrigY;
    const float* offOrigZ;
    const float* DSO;
    const float* offDetecU;
    const float* offDetecV;
    const float* DSD;
    const float* dRoll;
    const float* dPitch;
    const float* dYaw;
    const float* COR;
    float accuracy;
    int mode;
} TigreJuliaGeometry;

int tigre_julia_ax(
    const float* volume,
    const TigreJuliaGeometry* geometry,
    const float* angles,
    int nangles,
    int projection_type,
    const int* gpu_ids,
    int gpu_count,
    float* projections_out);

int tigre_julia_atb(
    const float* projections,
    const TigreJuliaGeometry* geometry,
    const float* angles,
    int nangles,
    int backprojection_type,
    const int* gpu_ids,
    int gpu_count,
    float* volume_out);

int tigre_julia_min_tv(
    const float* volume,
    int nVoxelX,
    int nVoxelY,
    int nVoxelZ,
    float alpha,
    int maxiter,
    const int* gpu_ids,
    int gpu_count,
    float* volume_out);

int tigre_julia_awmin_tv(
    const float* volume,
    int nVoxelX,
    int nVoxelY,
    int nVoxelZ,
    float alpha,
    int maxiter,
    float delta,
    const int* gpu_ids,
    int gpu_count,
    float* volume_out);

int tigre_julia_tvdenoise(
    const float* volume,
    int nVoxelX,
    int nVoxelY,
    int nVoxelZ,
    float lambda,
    const float* spacing_xyz,
    int maxiter,
    const int* gpu_ids,
    int gpu_count,
    float* volume_out);

int tigre_julia_piccs_tv(
    const float* volume,
    const float* prior,
    int nVoxelX,
    int nVoxelY,
    int nVoxelZ,
    float alpha,
    float ratio,
    int maxiter,
    const int* gpu_ids,
    int gpu_count,
    float* volume_out);

int tigre_julia_get_gpu_count(void);
int tigre_julia_get_gpu_name(int device_id, char* name, size_t name_len);

void tigre_julia_clear_last_error(void) noexcept;
const char* tigre_julia_last_error_message(void) noexcept;
const char* tigre_julia_last_error_tag(void) noexcept;
const char* tigre_julia_error_string(int status);

#ifdef __cplusplus
}
#endif

#endif
