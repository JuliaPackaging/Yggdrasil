#include "tigre_julia_shim.h"

#include <algorithm>
#include <cstring>
#include <functional>
#include <string>
#include <vector>

#include "GpuIds.hpp"
#include "GD_AwTV.hpp"
#include "GD_TV.hpp"
#undef GD_TV_HPP
#include "PICCS.hpp"
#include "Siddon_projection.hpp"
#include "Siddon_projection_parallel.hpp"
#include "gpuUtils.hpp"
#include "ray_interpolated_projection.hpp"
#include "ray_interpolated_projection_parallel.hpp"
#include "tigre_julia_runtime.hpp"
#include "types_TIGRE.hpp"
#include "tv_proximal.hpp"
#include "voxel_backprojection.hpp"
#include "voxel_backprojection2.hpp"
#include "voxel_backprojection_parallel.hpp"

namespace {

Geometry convert_geometry(const TigreJuliaGeometry& src) {
    Geometry dst{};
    dst.nVoxelX = src.nVoxelX;
    dst.nVoxelY = src.nVoxelY;
    dst.nVoxelZ = src.nVoxelZ;
    dst.sVoxelX = src.sVoxelX;
    dst.sVoxelY = src.sVoxelY;
    dst.sVoxelZ = src.sVoxelZ;
    dst.dVoxelX = src.dVoxelX;
    dst.dVoxelY = src.dVoxelY;
    dst.dVoxelZ = src.dVoxelZ;
    dst.nDetecU = src.nDetecU;
    dst.nDetecV = src.nDetecV;
    dst.sDetecU = src.sDetecU;
    dst.sDetecV = src.sDetecV;
    dst.dDetecU = src.dDetecU;
    dst.dDetecV = src.dDetecV;
    dst.offOrigX = const_cast<float*>(src.offOrigX);
    dst.offOrigY = const_cast<float*>(src.offOrigY);
    dst.offOrigZ = const_cast<float*>(src.offOrigZ);
    dst.DSO = const_cast<float*>(src.DSO);
    dst.offDetecU = const_cast<float*>(src.offDetecU);
    dst.offDetecV = const_cast<float*>(src.offDetecV);
    dst.DSD = const_cast<float*>(src.DSD);
    dst.dRoll = const_cast<float*>(src.dRoll);
    dst.dPitch = const_cast<float*>(src.dPitch);
    dst.dYaw = const_cast<float*>(src.dYaw);
    dst.COR = const_cast<float*>(src.COR);
    dst.unitX = 1.0f;
    dst.unitY = 1.0f;
    dst.unitZ = 1.0f;
    dst.alpha = 0.0f;
    dst.theta = 0.0f;
    dst.psi = 0.0f;
    dst.maxLength = 0.0f;
    dst.accuracy = src.accuracy;
    return dst;
}

bool geometry_has_nulls(const TigreJuliaGeometry& geo) {
    return geo.offOrigX == nullptr || geo.offOrigY == nullptr || geo.offOrigZ == nullptr ||
           geo.DSO == nullptr || geo.offDetecU == nullptr || geo.offDetecV == nullptr ||
           geo.DSD == nullptr || geo.dRoll == nullptr || geo.dPitch == nullptr ||
           geo.dYaw == nullptr || geo.COR == nullptr;
}

GpuIds make_gpu_ids(const int* gpu_ids, int gpu_count) {
    GpuIds ids;
    if (gpu_count > 0 && gpu_ids != nullptr) {
        ids.SetIds(gpu_count, const_cast<int*>(gpu_ids));
    } else {
        const int device_count = GetGpuCount();
        std::vector<int> all_ids(static_cast<size_t>(std::max(device_count, 0)));
        for (int i = 0; i < device_count; ++i) {
            all_ids[static_cast<size_t>(i)] = i;
        }
        ids.SetIds(device_count, all_ids.data());
    }
    return ids;
}

int wrap_call(const char* tag, const std::function<void()>& fn) {
    try {
        tigre_julia_clear_last_error();
        fn();
        return TIGRE_JULIA_STATUS_SUCCESS;
    } catch (const TigreJuliaError& err) {
        tigre_julia_set_last_error(err.tag(), err.what());
        return TIGRE_JULIA_STATUS_RUNTIME_ERROR;
    } catch (const std::exception& err) {
        tigre_julia_set_last_error(tag, err.what());
        return TIGRE_JULIA_STATUS_RUNTIME_ERROR;
    } catch (...) {
        tigre_julia_set_last_error(tag, "unknown C++ exception");
        return TIGRE_JULIA_STATUS_RUNTIME_ERROR;
    }
}

bool valid_volume_dims(int nVoxelX, int nVoxelY, int nVoxelZ) {
    return nVoxelX > 0 && nVoxelY > 0 && nVoxelZ > 0;
}

void fill_image_size(long (&image_size)[3], int nVoxelX, int nVoxelY, int nVoxelZ) {
    image_size[0] = static_cast<long>(nVoxelX);
    image_size[1] = static_cast<long>(nVoxelY);
    image_size[2] = static_cast<long>(nVoxelZ);
}

}  // namespace

extern "C" int tigre_julia_ax(
    const float* volume,
    const TigreJuliaGeometry* geometry,
    const float* angles,
    int nangles,
    int projection_type,
    const int* gpu_ids,
    int gpu_count,
    float* projections_out) {
    if (volume == nullptr || geometry == nullptr || angles == nullptr || projections_out == nullptr ||
        nangles <= 0 || geometry_has_nulls(*geometry)) {
        tigre_julia_set_last_error("tigre_julia_ax", "null pointer or invalid argument");
        return TIGRE_JULIA_STATUS_INVALID_ARGUMENT;
    }

    return wrap_call("tigre_julia_ax", [&]() {
        Geometry native_geo = convert_geometry(*geometry);
        GpuIds ids = make_gpu_ids(gpu_ids, gpu_count);
        std::vector<float*> result_ptrs(static_cast<size_t>(nangles));
        const size_t pixels_per_projection =
            static_cast<size_t>(geometry->nDetecU) * static_cast<size_t>(geometry->nDetecV);
        for (int i = 0; i < nangles; ++i) {
            result_ptrs[static_cast<size_t>(i)] =
                projections_out + static_cast<size_t>(i) * pixels_per_projection;
        }

        if (geometry->mode == TIGRE_JULIA_MODE_PARALLEL) {
            if (projection_type == TIGRE_JULIA_PROJECTION_INTERPOLATED) {
                interpolation_projection_parallel(
                    const_cast<float*>(volume), native_geo, result_ptrs.data(), angles, nangles, ids);
            } else {
                siddon_ray_projection_parallel(
                    const_cast<float*>(volume), native_geo, result_ptrs.data(), angles, nangles, ids);
            }
        } else {
            if (projection_type == TIGRE_JULIA_PROJECTION_INTERPOLATED) {
                interpolation_projection(
                    const_cast<float*>(volume), native_geo, result_ptrs.data(), angles, nangles, ids);
            } else {
                siddon_ray_projection(
                    const_cast<float*>(volume), native_geo, result_ptrs.data(), angles, nangles, ids);
            }
        }
    });
}

extern "C" int tigre_julia_atb(
    const float* projections,
    const TigreJuliaGeometry* geometry,
    const float* angles,
    int nangles,
    int backprojection_type,
    const int* gpu_ids,
    int gpu_count,
    float* volume_out) {
    if (projections == nullptr || geometry == nullptr || angles == nullptr || volume_out == nullptr ||
        nangles <= 0 || geometry_has_nulls(*geometry)) {
        tigre_julia_set_last_error("tigre_julia_atb", "null pointer or invalid argument");
        return TIGRE_JULIA_STATUS_INVALID_ARGUMENT;
    }

    return wrap_call("tigre_julia_atb", [&]() {
        Geometry native_geo = convert_geometry(*geometry);
        GpuIds ids = make_gpu_ids(gpu_ids, gpu_count);

        if (geometry->mode == TIGRE_JULIA_MODE_PARALLEL) {
            voxel_backprojection_parallel(
                const_cast<float*>(projections), native_geo, volume_out, angles, nangles, ids);
        } else if (backprojection_type == TIGRE_JULIA_BACKPROJECTION_MATCHED) {
            voxel_backprojection2(
                const_cast<float*>(projections), native_geo, volume_out, angles, nangles, ids);
        } else {
            voxel_backprojection(
                const_cast<float*>(projections), native_geo, volume_out, angles, nangles, ids);
        }
    });
}

extern "C" int tigre_julia_get_gpu_count(void) {
    return GetGpuCount();
}

extern "C" int tigre_julia_min_tv(
    const float* volume,
    int nVoxelX,
    int nVoxelY,
    int nVoxelZ,
    float alpha,
    int maxiter,
    const int* gpu_ids,
    int gpu_count,
    float* volume_out) {
    if (volume == nullptr || volume_out == nullptr || !valid_volume_dims(nVoxelX, nVoxelY, nVoxelZ) || maxiter < 0) {
        tigre_julia_set_last_error("tigre_julia_min_tv", "null pointer or invalid argument");
        return TIGRE_JULIA_STATUS_INVALID_ARGUMENT;
    }

    return wrap_call("tigre_julia_min_tv", [&]() {
        long image_size[3];
        fill_image_size(image_size, nVoxelX, nVoxelY, nVoxelZ);
        GpuIds ids = make_gpu_ids(gpu_ids, gpu_count);
        pocs_tv(const_cast<float*>(volume), volume_out, alpha, image_size, maxiter, ids);
    });
}

extern "C" int tigre_julia_awmin_tv(
    const float* volume,
    int nVoxelX,
    int nVoxelY,
    int nVoxelZ,
    float alpha,
    int maxiter,
    float delta,
    const int* gpu_ids,
    int gpu_count,
    float* volume_out) {
    if (volume == nullptr || volume_out == nullptr || !valid_volume_dims(nVoxelX, nVoxelY, nVoxelZ) || maxiter < 0) {
        tigre_julia_set_last_error("tigre_julia_awmin_tv", "null pointer or invalid argument");
        return TIGRE_JULIA_STATUS_INVALID_ARGUMENT;
    }

    return wrap_call("tigre_julia_awmin_tv", [&]() {
        long image_size[3];
        fill_image_size(image_size, nVoxelX, nVoxelY, nVoxelZ);
        GpuIds ids = make_gpu_ids(gpu_ids, gpu_count);
        aw_pocs_tv(const_cast<float*>(volume), volume_out, alpha, image_size, maxiter, delta, ids);
    });
}

extern "C" int tigre_julia_tvdenoise(
    const float* volume,
    int nVoxelX,
    int nVoxelY,
    int nVoxelZ,
    float lambda,
    const float* spacing_xyz,
    int maxiter,
    const int* gpu_ids,
    int gpu_count,
    float* volume_out) {
    if (volume == nullptr || volume_out == nullptr || spacing_xyz == nullptr ||
        !valid_volume_dims(nVoxelX, nVoxelY, nVoxelZ) || maxiter < 0) {
        tigre_julia_set_last_error("tigre_julia_tvdenoise", "null pointer or invalid argument");
        return TIGRE_JULIA_STATUS_INVALID_ARGUMENT;
    }

    return wrap_call("tigre_julia_tvdenoise", [&]() {
        long image_size[3];
        fill_image_size(image_size, nVoxelX, nVoxelY, nVoxelZ);
        GpuIds ids = make_gpu_ids(gpu_ids, gpu_count);
        tvdenoising(const_cast<float*>(volume), volume_out, lambda, spacing_xyz, image_size, maxiter, ids);
    });
}

extern "C" int tigre_julia_piccs_tv(
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
    float* volume_out) {
    if (volume == nullptr || prior == nullptr || volume_out == nullptr ||
        !valid_volume_dims(nVoxelX, nVoxelY, nVoxelZ) || maxiter < 0) {
        tigre_julia_set_last_error("tigre_julia_piccs_tv", "null pointer or invalid argument");
        return TIGRE_JULIA_STATUS_INVALID_ARGUMENT;
    }

    return wrap_call("tigre_julia_piccs_tv", [&]() {
        long image_size[3];
        fill_image_size(image_size, nVoxelX, nVoxelY, nVoxelZ);
        GpuIds ids = make_gpu_ids(gpu_ids, gpu_count);
        piccs_tv(volume, prior, volume_out, alpha, ratio, image_size, maxiter, ids);
    });
}

extern "C" int tigre_julia_get_gpu_name(int device_id, char* name, size_t name_len) {
    if (name == nullptr || name_len == 0 || device_id < 0) {
        tigre_julia_set_last_error("tigre_julia_get_gpu_name", "invalid output buffer");
        return TIGRE_JULIA_STATUS_INVALID_ARGUMENT;
    }

    char local_name[128];
    GetGpuName(device_id, local_name);
    std::strncpy(name, local_name, name_len - 1);
    name[name_len - 1] = '\0';
    return TIGRE_JULIA_STATUS_SUCCESS;
}

extern "C" const char* tigre_julia_error_string(int status) {
    switch (status) {
        case TIGRE_JULIA_STATUS_SUCCESS:
            return "success";
        case TIGRE_JULIA_STATUS_INVALID_ARGUMENT:
            return "invalid argument";
        case TIGRE_JULIA_STATUS_RUNTIME_ERROR:
            return "native runtime error";
        default:
            return "unknown status";
    }
}
