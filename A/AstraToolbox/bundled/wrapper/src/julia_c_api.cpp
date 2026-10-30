#include "astra/julia_c_api.h"

#include "astra/Data.h"
#include "astra/Data2D.h"
#include "astra/Data3D.h"
#include "astra/BackProjectionAlgorithm.h"
#include "astra/ConeProjectionGeometry3D.h"
#include "astra/CylConeVecProjectionGeometry3D.h"
#include "astra/CudaBackProjectionAlgorithm.h"
#include "astra/CudaCglsAlgorithm.h"
#include "astra/CudaCglsAlgorithm3D.h"
#include "astra/CudaProjector3D.h"
#include "astra/CudaFilteredBackProjectionAlgorithm.h"
#include "astra/CudaEMAlgorithm.h"
#include "astra/CudaFDKAlgorithm3D.h"
#include "astra/CudaSartAlgorithm.h"
#include "astra/CudaSirtAlgorithm.h"
#include "astra/CudaSirtAlgorithm3D.h"
#include "astra/XMLConfig.h"
#include "astra/FanFlatBeamLineKernelProjector2D.h"
#include "astra/FanFlatProjectionGeometry2D.h"
#include "astra/FanFlatVecProjectionGeometry2D.h"
#include "astra/FilteredBackProjectionAlgorithm.h"
#include "astra/ForwardProjectionAlgorithm.h"
#include "astra/CompositeGeometryManager.h"
#include "astra/ConeVecProjectionGeometry3D.h"
#include "astra/ParallelBeamLineKernelProjector2D.h"
#include "astra/ParallelProjectionGeometry2D.h"
#include "astra/ParallelProjectionGeometry3D.h"
#include "astra/ParallelVecProjectionGeometry2D.h"
#include "astra/ParallelVecProjectionGeometry3D.h"
#include "astra/VolumeGeometry2D.h"
#include "astra/VolumeGeometry3D.h"
#include "astra/ArtAlgorithm.h"
#include "astra/CglsAlgorithm.h"
#include "astra/FanFlatBeamStripKernelProjector2D.h"
#include "astra/Features.h"
#include "astra/ParallelBeamLinearKernelProjector2D.h"
#include "astra/ParallelBeamStripKernelProjector2D.h"
#include "astra/ParallelBeamDistanceDrivenProjector2D.h"
#include "astra/SparseMatrix.h"
#include "astra/SparseMatrixProjectionGeometry2D.h"
#include "astra/SparseMatrixProjector2D.h"
#include "astra/SartAlgorithm.h"
#include "astra/SirtAlgorithm.h"

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
#include "astra/cuda/2d/astra.h"
#include "astra/cuda/2d/fbp.h"
#include "astra/cuda/2d/sart.h"
#include "astra/cuda/2d/darthelper.h"
#include "astra/cuda/3d/astra3d.h"
#include "astra/cuda/3d/dims3d.h"
#include "astra/cuda/3d/darthelper3d.h"
#endif

#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

namespace {

class BorrowedFloat32Memory : public astra::CDataMemory<astra::float32> {
public:
	explicit BorrowedFloat32Memory(float* ptr) { m_pfData = ptr; }
	~BorrowedFloat32Memory() override { m_pfData = nullptr; }
};

class BorrowedSparseMatrix : public astra::CSparseMatrix {
public:
	BorrowedSparseMatrix(unsigned int height, unsigned int width, unsigned long nnz,
	                     const float* values, const uint32_t* col_indices, const uint64_t* row_starts)
	{
		m_iHeight = height;
		m_iWidth = width;
		m_lSize = nnz;
		m_pfValues = const_cast<float*>(values);
		m_piColIndices = const_cast<unsigned int*>(reinterpret_cast<const unsigned int*>(col_indices));
		m_plRowStarts = const_cast<unsigned long*>(reinterpret_cast<const unsigned long*>(row_starts));
		m_bInitialized = true;
	}
	~BorrowedSparseMatrix()
	{
		m_pfValues = nullptr;
		m_piColIndices = nullptr;
		m_plRowStarts = nullptr;
	}
};

class BorrowedFilteredBackProjectionAlgorithm : public astra::CFilteredBackProjectionAlgorithm {
public:
	bool initializeWithFilter(astra::CProjector2D* projector,
	                          astra::CFloat32VolumeData2D* reconstruction,
	                          astra::CFloat32ProjectionData2D* sinogram,
	                          const astra::SFilterConfig& filter_config)
	{
		m_pProjector = projector;
		m_pReconstruction = reconstruction;
		m_pSinogram = sinogram;
		m_filterConfig = filter_config;
		m_bIsInitialized = _check();
		return m_bIsInitialized;
	}
};

class BorrowedSirtAlgorithm : public astra::CSirtAlgorithm {
public:
	bool initializeWithOptions(astra::CProjector2D* projector,
	                           astra::CFloat32ProjectionData2D* sinogram,
	                           astra::CFloat32VolumeData2D* reconstruction,
	                           float relaxation,
	                           int use_min_constraint, float min_constraint,
	                           int use_max_constraint, float max_constraint)
	{
		if (!astra::CSirtAlgorithm::initialize(projector, sinogram, reconstruction)) {
			return false;
		}
		m_fLambda = relaxation;
		setConstraints(use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint);
		return true;
	}
};

class BorrowedSartAlgorithm : public astra::CSartAlgorithm {
public:
	bool initializeWithOptions(astra::CProjector2D* projector,
	                           astra::CFloat32ProjectionData2D* sinogram,
	                           astra::CFloat32VolumeData2D* reconstruction,
	                           float relaxation,
	                           const int* projection_order,
	                           int projection_order_length,
	                           int use_min_constraint, float min_constraint,
	                           int use_max_constraint, float max_constraint)
	{
		bool ok = false;
		if (projection_order && projection_order_length > 0) {
			std::vector<int> order(projection_order, projection_order + projection_order_length);
			ok = astra::CSartAlgorithm::initialize(projector, sinogram, reconstruction, order.data(), static_cast<int>(order.size()));
		} else {
			ok = astra::CSartAlgorithm::initialize(projector, sinogram, reconstruction);
		}
		if (!ok) return false;
		m_fLambda = relaxation;
		setConstraints(use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint);
		return true;
	}
};

class BorrowedCglsAlgorithm : public astra::CCglsAlgorithm {
public:
	bool initializeWithOptions(astra::CProjector2D* projector,
	                           astra::CFloat32ProjectionData2D* sinogram,
	                           astra::CFloat32VolumeData2D* reconstruction,
	                           int use_min_constraint, float min_constraint,
	                           int use_max_constraint, float max_constraint)
	{
		if (!astra::CCglsAlgorithm::initialize(projector, sinogram, reconstruction)) {
			return false;
		}
		setConstraints(use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint);
		return true;
	}
};

class BorrowedArtAlgorithm : public astra::CArtAlgorithm {
public:
	bool initializeWithOptions(astra::CProjector2D* projector,
	                           astra::CFloat32ProjectionData2D* sinogram,
	                           astra::CFloat32VolumeData2D* reconstruction,
	                           float relaxation,
	                           int use_min_constraint, float min_constraint,
	                           int use_max_constraint, float max_constraint)
	{
		if (!astra::CArtAlgorithm::initialize(projector, sinogram, reconstruction)) {
			return false;
		}
		setLambda(relaxation);
		setConstraints(use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint);
		return true;
	}
};

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
class BorrowedCudaSartAlgorithm : public astra::CCudaSartAlgorithm {
public:
	bool initializeWithOptions(astra::CFloat32ProjectionData2D* sinogram,
	                           astra::CFloat32VolumeData2D* reconstruction,
	                           float relaxation,
	                           int gpu_index,
	                           int detector_supersampling,
	                           int pixel_supersampling,
	                           int projection_order_mode,
	                           const int* projection_order,
	                           int projection_order_length,
	                           int angle_count)
	{
		if (!astra::CCudaSartAlgorithm::initialize(nullptr, sinogram, reconstruction)) {
			return false;
		}
		m_fLambda = relaxation;
		setGPUIndex(gpu_index);
		m_iDetectorSuperSampling = detector_supersampling;
		m_iPixelSuperSampling = pixel_supersampling;

		astraCUDA::SART* sart = dynamic_cast<astraCUDA::SART*>(m_pAlgo);
		if (!sart) {
			return false;
		}

		std::vector<int> order;
		if (projection_order_mode == 1) {
			order.resize(angle_count);
			for (int i = 0; i < angle_count; ++i) {
				order[i] = i;
			}
		} else if (projection_order_mode == 0) {
			order.resize(angle_count);
			for (int i = 0; i < angle_count; ++i) {
				order[i] = i;
			}
			for (int i = 0; i < angle_count - 1; ++i) {
				const int k = std::rand() % (angle_count - i);
				const int t = order[i];
				order[i] = order[i + k];
				order[i + k] = t;
			}
		} else {
			order.assign(projection_order, projection_order + projection_order_length);
		}

		if (!sart->setProjectionOrder(order.data(), static_cast<int>(order.size()))) {
			return false;
		}

		return true;
	}
};

class BorrowedCudaSirtAlgorithm : public astra::CCudaSirtAlgorithm {
public:
	bool initializeWithOptions(astra::CFloat32ProjectionData2D* sinogram,
	                           astra::CFloat32VolumeData2D* reconstruction,
	                           float relaxation,
	                           int gpu_index,
	                           int detector_supersampling,
	                           int pixel_supersampling)
	{
		if (!astra::CCudaSirtAlgorithm::initialize(nullptr, sinogram, reconstruction)) {
			return false;
		}
		m_fLambda = relaxation;
		setGPUIndex(gpu_index);
		m_iDetectorSuperSampling = detector_supersampling;
		m_iPixelSuperSampling = pixel_supersampling;
		return true;
	}
};

class BorrowedCudaBackProjectionAlgorithm : public astra::CCudaBackProjectionAlgorithm {
public:
	bool initializeWithOptions(astra::CFloat32ProjectionData2D* sinogram,
	                           astra::CFloat32VolumeData2D* reconstruction,
	                           int gpu_index,
	                           int detector_supersampling,
	                           int pixel_supersampling)
	{
		if (!astra::CCudaBackProjectionAlgorithm::initialize(nullptr, sinogram, reconstruction)) {
			return false;
		}
		m_iGPUIndex = gpu_index;
		m_iDetectorSuperSampling = detector_supersampling;
		m_iPixelSuperSampling = pixel_supersampling;
		return true;
	}
};

class BorrowedCudaCglsAlgorithm : public astra::CCudaCglsAlgorithm {
public:
	bool initializeWithOptions(astra::CFloat32ProjectionData2D* sinogram,
	                           astra::CFloat32VolumeData2D* reconstruction,
	                           int gpu_index,
	                           int detector_supersampling,
	                           int pixel_supersampling)
	{
		if (!astra::CCudaCglsAlgorithm::initialize(nullptr, sinogram, reconstruction)) {
			return false;
		}
		m_iGPUIndex = gpu_index;
		m_iDetectorSuperSampling = detector_supersampling;
		m_iPixelSuperSampling = pixel_supersampling;
		return true;
	}
};

class BorrowedCudaEMAlgorithm : public astra::CCudaEMAlgorithm {
public:
	bool initializeWithOptions(astra::CFloat32ProjectionData2D* sinogram,
	                           astra::CFloat32VolumeData2D* reconstruction,
	                           int gpu_index,
	                           int detector_supersampling,
	                           int pixel_supersampling)
	{
		if (!astra::CCudaEMAlgorithm::initialize(nullptr, sinogram, reconstruction)) {
			return false;
		}
		m_iGPUIndex = gpu_index;
		m_iDetectorSuperSampling = detector_supersampling;
		m_iPixelSuperSampling = pixel_supersampling;
		return true;
	}
};

class BorrowedCudaSirtAlgorithm3D : public astra::CCudaSirtAlgorithm3D {
public:
	bool initializeWithOptions(astra::CFloat32ProjectionData3D* sinogram,
	                           astra::CFloat32VolumeData3D* reconstruction,
	                           float relaxation,
	                           int gpu_index,
	                           int voxel_supersampling,
	                           int detector_supersampling)
	{
		if (!astra::CCudaSirtAlgorithm3D::initialize(nullptr, sinogram, reconstruction)) {
			return false;
		}
		m_fLambda = relaxation;
		m_iGPUIndex = gpu_index;
		m_iVoxelSuperSampling = voxel_supersampling;
		m_iDetectorSuperSampling = detector_supersampling;
		return true;
	}
};

class BorrowedCudaCglsAlgorithm3D : public astra::CCudaCglsAlgorithm3D {
public:
	bool initializeWithOptions(astra::CFloat32ProjectionData3D* sinogram,
	                           astra::CFloat32VolumeData3D* reconstruction,
	                           int gpu_index,
	                           int voxel_supersampling,
	                           int detector_supersampling)
	{
		if (!astra::CCudaCglsAlgorithm3D::initialize(nullptr, sinogram, reconstruction)) {
			return false;
		}
		m_iGPUIndex = gpu_index;
		m_iVoxelSuperSampling = voxel_supersampling;
		m_iDetectorSuperSampling = detector_supersampling;
		return true;
	}
};

class BorrowedCudaFDKAlgorithm3D : public astra::CCudaFDKAlgorithm3D {
public:
	bool initializeWithOptions(astra::CFloat32ProjectionData3D* sinogram,
	                           astra::CFloat32VolumeData3D* reconstruction,
	                           const astra::SFilterConfig& filter_config,
	                           bool short_scan,
	                           int gpu_index,
	                           int voxel_supersampling)
	{
		if (!astra::CCudaFDKAlgorithm3D::initialize(
		        nullptr, sinogram, reconstruction, filter_config, short_scan)) {
			return false;
		}
		m_iGPUIndex = gpu_index;
		m_iVoxelSuperSampling = voxel_supersampling;
		return true;
	}
};

class BorrowedCudaProjector3D : public astra::CCudaProjector3D {
public:
	bool initializeWithOptions(const astra::CProjectionGeometry3D& projection_geometry,
	                           const astra::CVolumeGeometry3D& volume_geometry,
	                           astra::Cuda3DProjectionKernel projection_kernel,
	                           int voxel_supersampling,
	                           int detector_supersampling,
	                           int gpu_index)
	{
		m_pProjectionGeometry.reset(projection_geometry.clone());
		m_pVolumeGeometry.reset(volume_geometry.clone());
		m_projectionKernel = projection_kernel;
		m_iVoxelSuperSampling = voxel_supersampling;
		m_iDetectorSuperSampling = detector_supersampling;
		m_iGPUIndex = gpu_index;
		m_bIsInitialized = _check();
		return m_bIsInitialized;
	}
};
#endif

thread_local std::string g_last_error;

bool validate_gpu_index(int gpu_index)
{
	if (gpu_index < -1) {
		g_last_error = "gpu_index must be >= -1";
		return false;
	}
	return true;
}

bool validate_projector_kernel(int projector_kernel)
{
	if (projector_kernel < 0 || projector_kernel > 3) {
		g_last_error = "projector_kernel must be 0 (line), 1 (linear), 2 (strip), or 3 (distance_driven)";
		return false;
	}
	return true;
}

bool validate_iterations(int iterations)
{
	if (iterations <= 0) {
		g_last_error = "iterations must be positive";
		return false;
	}
	return true;
}

bool validate_relaxation(float relaxation)
{
	if (relaxation <= 0.0f) {
		g_last_error = "relaxation must be positive";
		return false;
	}
	return true;
}

bool validate_optional_volume_mask(float* mask, int volume_width, int volume_height)
{
	if (!mask) {
		return true;
	}
	if (volume_width <= 0 || volume_height <= 0) {
		g_last_error = "volume mask dimensions must be positive";
		return false;
	}
	return true;
}

bool validate_optional_sinogram_mask(float* mask, int detector_count, int angle_count)
{
	if (!mask) {
		return true;
	}
	if (detector_count <= 0 || angle_count <= 0) {
		g_last_error = "sinogram mask dimensions must be positive";
		return false;
	}
	return true;
}

bool validate_optional_volume_mask_3d(float* mask,
                                      int volume_width,
                                      int volume_height,
                                      int volume_depth)
{
	if (!mask) {
		return true;
	}
	if (volume_width <= 0 || volume_height <= 0 || volume_depth <= 0) {
		g_last_error = "3D volume mask dimensions must be positive";
		return false;
	}
	return true;
}

bool validate_optional_sinogram_mask_3d(float* mask,
                                        int detector_count_u,
                                        int angle_count,
                                        int detector_count_v)
{
	if (!mask) {
		return true;
	}
	if (detector_count_u <= 0 || angle_count <= 0 || detector_count_v <= 0) {
		g_last_error = "3D sinogram mask dimensions must be positive";
		return false;
	}
	return true;
}

bool validate_constraint_flag(int flag, const char* name)
{
	if (flag != 0 && flag != 1) {
		g_last_error = std::string(name) + " must be 0 or 1";
		return false;
	}
	return true;
}

bool validate_projection_order_mode(int projection_order_mode)
{
	if (projection_order_mode < 0 || projection_order_mode > 2) {
		g_last_error = "projection_order_mode must be 0, 1, or 2";
		return false;
	}
	return true;
}

bool validate_projection_order_list(int projection_order_mode,
                                    const int* projection_order,
                                    int projection_order_length,
                                    int angle_count)
{
	if (projection_order_mode != 2) {
		return true;
	}
	if (!projection_order) {
		g_last_error = "projection_order pointer is null for custom projection order";
		return false;
	}
	if (projection_order_length <= 0) {
		g_last_error = "projection_order_length must be positive for custom projection order";
		return false;
	}
	for (int i = 0; i < projection_order_length; ++i) {
		if (projection_order[i] < 0 || projection_order[i] >= angle_count) {
			g_last_error = "custom projection_order entry is out of range";
			return false;
		}
	}
	return true;
}

bool validate_short_scan_flag(int short_scan)
{
	if (short_scan != 0 && short_scan != 1) {
		g_last_error = "short_scan must be 0 or 1";
		return false;
	}
	return true;
}

bool is_supported_filter_type(int filter_type)
{
	switch (static_cast<astra::E_FBPFILTER>(filter_type)) {
	case astra::FILTER_NONE:
	case astra::FILTER_RAMLAK:
	case astra::FILTER_SHEPPLOGAN:
	case astra::FILTER_COSINE:
	case astra::FILTER_HAMMING:
	case astra::FILTER_HANN:
	case astra::FILTER_TUKEY:
	case astra::FILTER_LANCZOS:
	case astra::FILTER_TRIANGULAR:
	case astra::FILTER_GAUSSIAN:
	case astra::FILTER_BARTLETTHANN:
	case astra::FILTER_BLACKMAN:
	case astra::FILTER_NUTTALL:
	case astra::FILTER_BLACKMANHARRIS:
	case astra::FILTER_BLACKMANNUTTALL:
	case astra::FILTER_FLATTOP:
	case astra::FILTER_KAISER:
	case astra::FILTER_PARZEN:
	case astra::FILTER_PROJECTION:
	case astra::FILTER_SINOGRAM:
	case astra::FILTER_RPROJECTION:
	case astra::FILTER_RSINOGRAM:
		return true;
	default:
		return false;
	}
}

bool validate_filter_inputs(int filter_type,
                            const float* custom_filter,
                            int custom_filter_width,
                            int custom_filter_height,
                            float filter_d)
{
	if (!is_supported_filter_type(filter_type)) {
		g_last_error = "unsupported filter_type";
		return false;
	}
	if (filter_d <= 0.0f) {
		g_last_error = "filter_d must be positive";
		return false;
	}

	const astra::E_FBPFILTER filter = static_cast<astra::E_FBPFILTER>(filter_type);
	const bool is_custom =
	    filter == astra::FILTER_PROJECTION ||
	    filter == astra::FILTER_SINOGRAM ||
	    filter == astra::FILTER_RPROJECTION ||
	    filter == astra::FILTER_RSINOGRAM;

	if (is_custom) {
		if (!custom_filter) {
			g_last_error = "custom_filter pointer is null for custom filter_type";
			return false;
		}
		if (custom_filter_width <= 0 || custom_filter_height <= 0) {
			g_last_error = "custom filter dimensions must be positive";
			return false;
		}
	} else {
		if (custom_filter && (custom_filter_width <= 0 || custom_filter_height <= 0)) {
			g_last_error = "custom filter dimensions must be positive when custom_filter is provided";
			return false;
		}
	}

	return true;
}

astra::SFilterConfig build_filter_config(int filter_type,
                                         const float* custom_filter,
                                         int custom_filter_width,
                                         int custom_filter_height,
                                         float filter_d,
                                         float filter_parameter)
{
	astra::SFilterConfig filter_config;
	filter_config.m_eType = static_cast<astra::E_FBPFILTER>(filter_type);
	filter_config.m_fD = filter_d;
	filter_config.m_fParameter = filter_parameter;
	filter_config.m_iCustomFilterWidth = custom_filter_width;
	filter_config.m_iCustomFilterHeight = custom_filter_height;

	if (custom_filter && custom_filter_width > 0 && custom_filter_height > 0) {
		const size_t element_count =
		    static_cast<size_t>(custom_filter_width) * static_cast<size_t>(custom_filter_height);
		filter_config.m_pfCustomFilter.assign(custom_filter, custom_filter + element_count);
	}

	return filter_config;
}

bool validate_inputs(int volume_width,
                     int volume_height,
                     int angle_count,
                     int detector_count,
                     float detector_width,
                     const float* angles,
                     float* volume,
                     float* sinogram)
{
	if (volume_width <= 0 || volume_height <= 0) {
		g_last_error = "volume dimensions must be positive";
		return false;
	}
	if (angle_count <= 0 || detector_count <= 0) {
		g_last_error = "projection dimensions must be positive";
		return false;
	}
	if (detector_width <= 0.0f) {
		g_last_error = "detector width must be positive";
		return false;
	}
	if (!angles) {
		g_last_error = "angles pointer is null";
		return false;
	}
	if (!volume) {
		g_last_error = "volume pointer is null";
		return false;
	}
	if (!sinogram) {
		g_last_error = "sinogram pointer is null";
		return false;
	}
	return true;
}

bool validate_fanflat_distances(float origin_source_distance,
                                float origin_detector_distance)
{
	if (origin_source_distance <= 0.0f) {
		g_last_error = "origin_source_distance must be positive";
		return false;
	}
	if (origin_detector_distance <= 0.0f) {
		g_last_error = "origin_detector_distance must be positive";
		return false;
	}
	return true;
}

bool validate_vec_inputs_2d(int volume_width,
                            int volume_height,
                            int angle_count,
                            int detector_count,
                            const float* vectors,
                            const float* input,
                            float* output)
{
	if (volume_width <= 0 || volume_height <= 0) {
		g_last_error = "volume dimensions must be positive";
		return false;
	}
	if (angle_count <= 0 || detector_count <= 0) {
		g_last_error = "projection dimensions must be positive";
		return false;
	}
	if (!vectors) {
		g_last_error = "vectors pointer is null";
		return false;
	}
	if (!input) {
		g_last_error = "input pointer is null";
		return false;
	}
	if (!output) {
		g_last_error = "output pointer is null";
		return false;
	}
	return true;
}

bool validate_sparse_matrix_inputs(int volume_width,
                                   int volume_height,
                                   int angle_count,
                                   int detector_count,
                                   uint64_t nnz,
                                   const uint64_t* row_starts,
                                   const uint32_t* col_indices,
                                   const float* values,
                                   const float* input,
                                   const float* output)
{
	if (volume_width <= 0 || volume_height <= 0) {
		g_last_error = "volume dimensions must be positive";
		return false;
	}
	if (angle_count <= 0 || detector_count <= 0) {
		g_last_error = "projection dimensions must be positive";
		return false;
	}
	if (!row_starts || !col_indices || !values || !input || !output) {
		g_last_error = "null pointer passed to sparse matrix function";
		return false;
	}
	if (row_starts[0] != 0 || row_starts[angle_count * detector_count] != nnz) {
		g_last_error = "row_starts must start at 0 and end at nnz";
		return false;
	}
	return true;
}

bool validate_detector_supersampling(int detector_supersampling)
{
	if (detector_supersampling <= 0) {
		g_last_error = "detector_supersampling must be positive";
		return false;
	}
	return true;
}

bool validate_pixel_supersampling(int pixel_supersampling)
{
	if (pixel_supersampling <= 0) {
		g_last_error = "pixel_supersampling must be positive";
		return false;
	}
	return true;
}

bool validate_voxel_supersampling(int voxel_supersampling)
{
	if (voxel_supersampling <= 0) {
		g_last_error = "voxel_supersampling must be positive";
		return false;
	}
	return true;
}

bool validate_cone_distances(float origin_source_distance,
                             float origin_detector_distance)
{
	if (origin_source_distance <= 0.0f) {
		g_last_error = "origin_source_distance must be positive";
		return false;
	}
	if (origin_detector_distance <= 0.0f) {
		g_last_error = "origin_detector_distance must be positive";
		return false;
	}
	return true;
}

bool validate_inputs_3d(int volume_width,
                        int volume_height,
                        int volume_depth,
                        int angle_count,
                        int detector_count_u,
                        int detector_count_v,
                        float detector_spacing_u,
                        float detector_spacing_v,
                        const float* angles,
                        const float* volume,
                        float* sinogram)
{
	if (volume_width <= 0 || volume_height <= 0 || volume_depth <= 0) {
		g_last_error = "volume dimensions must be positive";
		return false;
	}
	if (angle_count <= 0 || detector_count_u <= 0 || detector_count_v <= 0) {
		g_last_error = "projection dimensions must be positive";
		return false;
	}
	if (detector_spacing_u <= 0.0f || detector_spacing_v <= 0.0f) {
		g_last_error = "detector spacing must be positive";
		return false;
	}
	if (!angles) {
		g_last_error = "angles pointer is null";
		return false;
	}
	if (!volume) {
		g_last_error = "volume pointer is null";
		return false;
	}
	if (!sinogram) {
		g_last_error = "sinogram pointer is null";
		return false;
	}
	return true;
}

bool validate_vec_inputs_3d(int volume_width,
                            int volume_height,
                            int volume_depth,
                            int angle_count,
                            int detector_count_u,
                            int detector_count_v,
                            const float* vectors,
                            const float* input,
                            float* output)
{
	if (volume_width <= 0 || volume_height <= 0 || volume_depth <= 0) {
		g_last_error = "volume dimensions must be positive";
		return false;
	}
	if (angle_count <= 0 || detector_count_u <= 0 || detector_count_v <= 0) {
		g_last_error = "projection dimensions must be positive";
		return false;
	}
	if (!vectors) {
		g_last_error = "vectors pointer is null";
		return false;
	}
	if (!input) {
		g_last_error = "input pointer is null";
		return false;
	}
	if (!output) {
		g_last_error = "output pointer is null";
		return false;
	}
	return true;
}

std::vector<astra::SPar3DProjection> build_parallel_vec_geometry(
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    const float* vectors)
{
	std::vector<astra::SPar3DProjection> projection_vectors;
	projection_vectors.resize(angle_count);

	for (int i = 0; i < angle_count; ++i) {
		const float* v = vectors + 12 * i;
		auto& p = projection_vectors[i];
		p.fRayX = v[0];
		p.fRayY = v[1];
		p.fRayZ = v[2];
		p.fDetUX = v[6];
		p.fDetUY = v[7];
		p.fDetUZ = v[8];
		p.fDetVX = v[9];
		p.fDetVY = v[10];
		p.fDetVZ = v[11];
		p.fDetSX = v[3] - 0.5 * detector_count_v * p.fDetVX - 0.5 * detector_count_u * p.fDetUX;
		p.fDetSY = v[4] - 0.5 * detector_count_v * p.fDetVY - 0.5 * detector_count_u * p.fDetUY;
		p.fDetSZ = v[5] - 0.5 * detector_count_v * p.fDetVZ - 0.5 * detector_count_u * p.fDetUZ;
	}

	return projection_vectors;
}

std::vector<astra::SParProjection> build_parallel_vec_geometry_2d(
    int angle_count,
    int detector_count,
    const float* vectors)
{
	std::vector<astra::SParProjection> projection_vectors;
	projection_vectors.resize(angle_count);

	for (int i = 0; i < angle_count; ++i) {
		const float* v = vectors + 6 * i;
		auto& p = projection_vectors[i];
		p.fRayX = v[0];
		p.fRayY = v[1];
		p.fDetUX = v[4];
		p.fDetUY = v[5];
		p.fDetSX = v[2] - 0.5f * detector_count * p.fDetUX;
		p.fDetSY = v[3] - 0.5f * detector_count * p.fDetUY;
	}

	return projection_vectors;
}

std::vector<astra::SFanProjection> build_fanflat_vec_geometry_2d(
    int angle_count,
    int detector_count,
    const float* vectors)
{
	std::vector<astra::SFanProjection> projection_vectors;
	projection_vectors.resize(angle_count);

	for (int i = 0; i < angle_count; ++i) {
		const float* v = vectors + 6 * i;
		auto& p = projection_vectors[i];
		p.fSrcX = v[0];
		p.fSrcY = v[1];
		p.fDetUX = v[4];
		p.fDetUY = v[5];
		p.fDetSX = v[2] - 0.5f * detector_count * p.fDetUX;
		p.fDetSY = v[3] - 0.5f * detector_count * p.fDetUY;
	}

	return projection_vectors;
}

std::vector<astra::SConeProjection> build_cone_vec_geometry(
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    const float* vectors)
{
	std::vector<astra::SConeProjection> projection_vectors;
	projection_vectors.resize(angle_count);

	for (int i = 0; i < angle_count; ++i) {
		const float* v = vectors + 12 * i;
		auto& p = projection_vectors[i];
		p.fSrcX = v[0];
		p.fSrcY = v[1];
		p.fSrcZ = v[2];
		p.fDetUX = v[6];
		p.fDetUY = v[7];
		p.fDetUZ = v[8];
		p.fDetVX = v[9];
		p.fDetVY = v[10];
		p.fDetVZ = v[11];
		p.fDetSX = v[3] - 0.5 * detector_count_v * p.fDetVX - 0.5 * detector_count_u * p.fDetUX;
		p.fDetSY = v[4] - 0.5 * detector_count_v * p.fDetVY - 0.5 * detector_count_u * p.fDetUY;
		p.fDetSZ = v[5] - 0.5 * detector_count_v * p.fDetVZ - 0.5 * detector_count_u * p.fDetUZ;
	}

	return projection_vectors;
}

std::vector<astra::SCylConeProjection> build_cyl_cone_vec_geometry(
    int angle_count,
    const float* vectors)
{
	std::vector<astra::SCylConeProjection> projection_vectors;
	projection_vectors.resize(angle_count);

	for (int i = 0; i < angle_count; ++i) {
		const float* v = vectors + 13 * i;
		auto& p = projection_vectors[i];
		p.fSrcX = v[0];
		p.fSrcY = v[1];
		p.fSrcZ = v[2];
		p.fDetCX = v[3];
		p.fDetCY = v[4];
		p.fDetCZ = v[5];
		p.fDetUX = v[6];
		p.fDetUY = v[7];
		p.fDetUZ = v[8];
		p.fDetVX = v[9];
		p.fDetVY = v[10];
		p.fDetVZ = v[11];
		p.fDetR = v[12];
	}

	return projection_vectors;
}

void fill_volume_geometry_config_node(astra::XMLNode node, const astra::CVolumeGeometry2D& volume_geometry)
{
	node.addChildNode("GridColCount", std::to_string(volume_geometry.getGridColCount()));
	node.addChildNode("GridRowCount", std::to_string(volume_geometry.getGridRowCount()));
	node.addOption("WindowMinX", volume_geometry.getWindowMinX());
	node.addOption("WindowMaxX", volume_geometry.getWindowMaxX());
	node.addOption("WindowMinY", volume_geometry.getWindowMinY());
	node.addOption("WindowMaxY", volume_geometry.getWindowMaxY());
}

void fill_vec_projection_config_node(astra::XMLNode node,
                                     const char* type,
                                     int angle_count,
                                     int detector_count,
                                     const float* vectors)
{
	node.addAttribute("type", type);
	node.addChildNode("DetectorCount", std::to_string(detector_count));
	astra::XMLNode vectors_node = node.addChildNode("Vectors");
	vectors_node.setContent(vectors, 6, angle_count, false);
}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
bool run_cuda_fbp_2d(astra::CVolumeGeometry2D& volume_geometry,
                     const astra::CProjectionGeometry2D& projection_geometry,
                     const float* sinogram,
                     float* volume,
                     const astra::SFilterConfig& filter_config,
                     bool short_scan,
                     int gpu_index)
{
	astra::CFloat32VolumeData2D volume_data(
	    volume_geometry, new BorrowedFloat32Memory(volume));
	astra::CFloat32ProjectionData2D sinogram_data(
	    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));

	if (volume_data.getFloat32Memory() != volume) {
		g_last_error = "volume buffer was not borrowed zero-copy";
		return false;
	}
	if (sinogram_data.getFloat32Memory() != sinogram) {
		g_last_error = "sinogram buffer was not borrowed zero-copy";
		return false;
	}

	astraCUDA::FBP algorithm;
	bool ok = true;
	ok &= algorithm.setGPUIndex(gpu_index);
	ok &= algorithm.setGeometry(&volume_geometry, &projection_geometry);
	ok &= algorithm.setSuperSampling(1, 1);
	ok &= algorithm.init();
	ok &= algorithm.setFilter(filter_config);
	ok &= algorithm.setShortScan(short_scan);
	ok &= algorithm.setReconstructionScale(1.0f / volume_geometry.getPixelArea());
	ok &= algorithm.allocateBuffers();
	ok &= algorithm.copyDataToGPU(
	    sinogram,
	    projection_geometry.getDetectorCount(),
	    volume,
	    volume_geometry.getGridColCount(),
	    nullptr,
	    0,
	    nullptr,
	    0);
	ok &= algorithm.iterate(1);
	ok &= algorithm.getReconstruction(volume, volume_geometry.getGridColCount());

	if (!ok) {
		g_last_error = "CUDA FBP execution failed";
		return false;
	}
	return true;
}

bool run_cuda_sirt_2d(astra::CVolumeGeometry2D& volume_geometry,
                      const astra::CProjectionGeometry2D& projection_geometry,
                      const float* sinogram,
                      float* volume,
                      int iterations,
                      float relaxation,
                      const float* reconstruction_mask,
                      const float* sinogram_mask,
                      float* residual_norm,
                      bool use_min_constraint,
                      float min_constraint,
                      bool use_max_constraint,
                      float max_constraint,
                      int detector_supersampling,
                      int pixel_supersampling,
                      int gpu_index)
{
	BorrowedCudaSirtAlgorithm algorithm;
	astra::CFloat32VolumeData2D volume_data(
	    volume_geometry, new BorrowedFloat32Memory(volume));
	astra::CFloat32ProjectionData2D sinogram_data(
	    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));
	std::unique_ptr<astra::CFloat32VolumeData2D> reconstruction_mask_data;
	std::unique_ptr<astra::CFloat32ProjectionData2D> sinogram_mask_data;

	if (volume_data.getFloat32Memory() != volume) {
		g_last_error = "volume buffer was not borrowed zero-copy";
		return false;
	}
	if (sinogram_data.getFloat32Memory() != sinogram) {
		g_last_error = "sinogram buffer was not borrowed zero-copy";
		return false;
	}
	if (!algorithm.initializeWithOptions(
	        &sinogram_data,
	        &volume_data,
	        relaxation,
	        gpu_index,
	        detector_supersampling,
	        pixel_supersampling)) {
		g_last_error = "failed to initialize CUDA SIRT algorithm";
		return false;
	}
	if (reconstruction_mask) {
		reconstruction_mask_data = std::make_unique<astra::CFloat32VolumeData2D>(
		    volume_geometry, new BorrowedFloat32Memory(const_cast<float*>(reconstruction_mask)));
		algorithm.setReconstructionMask(reconstruction_mask_data.get());
	}
		if (sinogram_mask) {
			sinogram_mask_data = std::make_unique<astra::CFloat32ProjectionData2D>(
			    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram_mask)));
			algorithm.setSinogramMask(sinogram_mask_data.get());
		}
		algorithm.setConstraints(use_min_constraint, min_constraint, use_max_constraint, max_constraint);
		if (!algorithm.run(iterations)) {
			g_last_error = "CUDA SIRT run failed";
			return false;
	}
	if (residual_norm) {
		astra::float32 residual = 0.0f;
		if (!algorithm.getResidualNorm(residual)) {
			g_last_error = "CUDA SIRT residual norm is unavailable";
			return false;
		}
		*residual_norm = residual;
	}
	return true;
}

bool run_cuda_cgls_2d(astra::CVolumeGeometry2D& volume_geometry,
                      const astra::CProjectionGeometry2D& projection_geometry,
                      const float* sinogram,
                      float* volume,
                      int iterations,
                      const float* reconstruction_mask,
                      float* residual_norm,
                      int detector_supersampling,
                      int pixel_supersampling,
                      int gpu_index)
{
	BorrowedCudaCglsAlgorithm algorithm;
	astra::CFloat32VolumeData2D volume_data(
	    volume_geometry, new BorrowedFloat32Memory(volume));
	astra::CFloat32ProjectionData2D sinogram_data(
	    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));
	std::unique_ptr<astra::CFloat32VolumeData2D> reconstruction_mask_data;

	if (volume_data.getFloat32Memory() != volume) {
		g_last_error = "volume buffer was not borrowed zero-copy";
		return false;
	}
	if (sinogram_data.getFloat32Memory() != sinogram) {
		g_last_error = "sinogram buffer was not borrowed zero-copy";
		return false;
	}
	if (!algorithm.initializeWithOptions(
	        &sinogram_data, &volume_data, gpu_index, detector_supersampling, pixel_supersampling)) {
		g_last_error = "failed to initialize CUDA CGLS algorithm";
		return false;
	}
	if (reconstruction_mask) {
		reconstruction_mask_data = std::make_unique<astra::CFloat32VolumeData2D>(
		    volume_geometry, new BorrowedFloat32Memory(const_cast<float*>(reconstruction_mask)));
		algorithm.setReconstructionMask(reconstruction_mask_data.get());
	}
	if (!algorithm.run(iterations)) {
		g_last_error = "CUDA CGLS run failed";
		return false;
	}
	if (residual_norm) {
		astra::float32 residual = 0.0f;
		if (!algorithm.getResidualNorm(residual)) {
			g_last_error = "CUDA CGLS residual norm is unavailable";
			return false;
		}
		*residual_norm = residual;
	}
	return true;
}

bool run_cuda_sart_2d(astra::CVolumeGeometry2D& volume_geometry,
                      const astra::CProjectionGeometry2D& projection_geometry,
                      const float* sinogram,
                      float* volume,
                      int iterations,
                      float relaxation,
                      const float* reconstruction_mask,
                      float* residual_norm,
                      bool use_min_constraint,
                      float min_constraint,
                      bool use_max_constraint,
                      float max_constraint,
                      int projection_order_mode,
                      const int* projection_order,
                      int projection_order_length,
                      int angle_count,
                      int detector_supersampling,
                      int pixel_supersampling,
                      int gpu_index)
{
	BorrowedCudaSartAlgorithm algorithm;
	astra::CFloat32VolumeData2D volume_data(
	    volume_geometry, new BorrowedFloat32Memory(volume));
	astra::CFloat32ProjectionData2D sinogram_data(
	    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));
	std::unique_ptr<astra::CFloat32VolumeData2D> reconstruction_mask_data;

	if (volume_data.getFloat32Memory() != volume) {
		g_last_error = "volume buffer was not borrowed zero-copy";
		return false;
	}
	if (sinogram_data.getFloat32Memory() != sinogram) {
		g_last_error = "sinogram buffer was not borrowed zero-copy";
		return false;
	}
	if (!algorithm.initializeWithOptions(
	        &sinogram_data,
	        &volume_data,
	        relaxation,
	        gpu_index,
	        detector_supersampling,
	        pixel_supersampling,
	        projection_order_mode,
	        projection_order,
	        projection_order_length,
	        angle_count)) {
		g_last_error = "failed to initialize CUDA SART algorithm";
		return false;
	}
	if (reconstruction_mask) {
		reconstruction_mask_data = std::make_unique<astra::CFloat32VolumeData2D>(
		    volume_geometry, new BorrowedFloat32Memory(const_cast<float*>(reconstruction_mask)));
		algorithm.setReconstructionMask(reconstruction_mask_data.get());
	}
	algorithm.setConstraints(use_min_constraint, min_constraint, use_max_constraint, max_constraint);
	if (!algorithm.run(iterations)) {
		g_last_error = "CUDA SART run failed";
		return false;
	}
	if (residual_norm) {
		astra::float32 residual = 0.0f;
		if (!algorithm.getResidualNorm(residual)) {
			g_last_error = "CUDA SART residual norm is unavailable";
			return false;
		}
		*residual_norm = residual;
	}
	return true;
}

bool run_cuda_em_2d(astra::CVolumeGeometry2D& volume_geometry,
                    const astra::CProjectionGeometry2D& projection_geometry,
                    const float* sinogram,
                    float* volume,
                    int iterations,
                    float* residual_norm,
                    int detector_supersampling,
                    int pixel_supersampling,
                    int gpu_index)
{
	BorrowedCudaEMAlgorithm algorithm;
	astra::CFloat32VolumeData2D volume_data(
	    volume_geometry, new BorrowedFloat32Memory(volume));
	astra::CFloat32ProjectionData2D sinogram_data(
	    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));

	if (volume_data.getFloat32Memory() != volume) {
		g_last_error = "volume buffer was not borrowed zero-copy";
		return false;
	}
	if (sinogram_data.getFloat32Memory() != sinogram) {
		g_last_error = "sinogram buffer was not borrowed zero-copy";
		return false;
	}
	if (!algorithm.initializeWithOptions(
	        &sinogram_data, &volume_data, gpu_index, detector_supersampling, pixel_supersampling)) {
		g_last_error = "failed to initialize CUDA EM algorithm";
		return false;
	}
	if (!algorithm.run(iterations)) {
		g_last_error = "CUDA EM run failed";
		return false;
	}
	if (residual_norm) {
		astra::float32 residual = 0.0f;
		if (!algorithm.getResidualNorm(residual)) {
			g_last_error = "CUDA EM residual norm is unavailable";
			return false;
		}
		*residual_norm = residual;
	}
	return true;
}

bool run_cuda_sirt_3d(astra::CVolumeGeometry3D& volume_geometry,
                      const astra::CProjectionGeometry3D& projection_geometry,
                      const float* sinogram,
                      float* volume,
                      int iterations,
                      float relaxation,
                      const float* reconstruction_mask,
                      const float* sinogram_mask,
                      float* residual_norm,
                      bool use_min_constraint,
                      float min_constraint,
                      bool use_max_constraint,
                      float max_constraint,
                      int voxel_supersampling,
                      int detector_supersampling,
                      int gpu_index)
{
	BorrowedCudaSirtAlgorithm3D algorithm;
	astra::CFloat32VolumeData3D volume_data(
	    volume_geometry, new BorrowedFloat32Memory(volume));
	astra::CFloat32ProjectionData3D sinogram_data(
	    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));
	std::unique_ptr<astra::CFloat32VolumeData3D> reconstruction_mask_data;
	std::unique_ptr<astra::CFloat32ProjectionData3D> sinogram_mask_data;

	if (volume_data.getFloat32Memory() != volume) {
		g_last_error = "3D volume buffer was not borrowed zero-copy";
		return false;
	}
	if (sinogram_data.getFloat32Memory() != sinogram) {
		g_last_error = "3D sinogram buffer was not borrowed zero-copy";
		return false;
	}
	if (!algorithm.initializeWithOptions(
	        &sinogram_data,
	        &volume_data,
	        relaxation,
	        gpu_index,
	        voxel_supersampling,
	        detector_supersampling)) {
		g_last_error = "failed to initialize CUDA SIRT3D algorithm";
		return false;
	}
	if (reconstruction_mask) {
		reconstruction_mask_data = std::make_unique<astra::CFloat32VolumeData3D>(
		    volume_geometry, new BorrowedFloat32Memory(const_cast<float*>(reconstruction_mask)));
		algorithm.setReconstructionMask(reconstruction_mask_data.get());
	}
	if (sinogram_mask) {
		sinogram_mask_data = std::make_unique<astra::CFloat32ProjectionData3D>(
		    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram_mask)));
		algorithm.setSinogramMask(sinogram_mask_data.get());
	}
	algorithm.setConstraints(use_min_constraint, min_constraint, use_max_constraint, max_constraint);
	if (!algorithm.run(iterations)) {
		g_last_error = "CUDA SIRT3D run failed";
		return false;
	}
	if (residual_norm) {
		astra::float32 residual = 0.0f;
		if (!algorithm.getResidualNorm(residual)) {
			g_last_error = "CUDA SIRT3D residual norm is unavailable";
			return false;
		}
		*residual_norm = residual;
	}
	return true;
}

bool run_cuda_cgls_3d(astra::CVolumeGeometry3D& volume_geometry,
                      const astra::CProjectionGeometry3D& projection_geometry,
                      const float* sinogram,
                      float* volume,
                      int iterations,
                      const float* reconstruction_mask,
                      float* residual_norm,
                      int voxel_supersampling,
                      int detector_supersampling,
                      int gpu_index)
{
	BorrowedCudaCglsAlgorithm3D algorithm;
	astra::CFloat32VolumeData3D volume_data(
	    volume_geometry, new BorrowedFloat32Memory(volume));
	astra::CFloat32ProjectionData3D sinogram_data(
	    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));
	std::unique_ptr<astra::CFloat32VolumeData3D> reconstruction_mask_data;

	if (volume_data.getFloat32Memory() != volume) {
		g_last_error = "3D volume buffer was not borrowed zero-copy";
		return false;
	}
	if (sinogram_data.getFloat32Memory() != sinogram) {
		g_last_error = "3D sinogram buffer was not borrowed zero-copy";
		return false;
	}
	if (!algorithm.initializeWithOptions(
	        &sinogram_data,
	        &volume_data,
	        gpu_index,
	        voxel_supersampling,
	        detector_supersampling)) {
		g_last_error = "failed to initialize CUDA CGLS3D algorithm";
		return false;
	}
	if (reconstruction_mask) {
		reconstruction_mask_data = std::make_unique<astra::CFloat32VolumeData3D>(
		    volume_geometry, new BorrowedFloat32Memory(const_cast<float*>(reconstruction_mask)));
		algorithm.setReconstructionMask(reconstruction_mask_data.get());
	}
	if (!algorithm.run(iterations)) {
		g_last_error = "CUDA CGLS3D run failed";
		return false;
	}
	if (residual_norm) {
		astra::float32 residual = 0.0f;
		if (!algorithm.getResidualNorm(residual)) {
			g_last_error = "CUDA CGLS3D residual norm is unavailable";
			return false;
		}
		*residual_norm = residual;
	}
	return true;
}

bool run_cuda_fdk_3d(astra::CVolumeGeometry3D& volume_geometry,
                     const astra::CProjectionGeometry3D& projection_geometry,
                     const float* sinogram,
                     float* volume,
                     const astra::SFilterConfig& filter_config,
                     bool short_scan,
                     int voxel_supersampling,
                     int gpu_index)
{
	BorrowedCudaFDKAlgorithm3D algorithm;
	astra::CFloat32VolumeData3D volume_data(
	    volume_geometry, new BorrowedFloat32Memory(volume));
	astra::CFloat32ProjectionData3D sinogram_data(
	    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));

	if (volume_data.getFloat32Memory() != volume) {
		g_last_error = "3D volume buffer was not borrowed zero-copy";
		return false;
	}
	if (sinogram_data.getFloat32Memory() != sinogram) {
		g_last_error = "3D sinogram buffer was not borrowed zero-copy";
		return false;
	}
	if (!algorithm.initializeWithOptions(
	        &sinogram_data,
	        &volume_data,
	        filter_config,
	        short_scan,
	        gpu_index,
	        voxel_supersampling)) {
		g_last_error = "failed to initialize CUDA FDK3D algorithm";
		return false;
	}
	if (!algorithm.run(1)) {
		g_last_error = "CUDA FDK3D run failed";
		return false;
	}
	return true;
}

bool run_cuda_fp_3d_cgm(astra::CVolumeGeometry3D& volume_geometry,
                        const astra::CProjectionGeometry3D& projection_geometry,
                        const float* volume,
                        float* sinogram,
                        int gpu_index)
{
	astra::CFloat32VolumeData3D volume_data(
	    volume_geometry, new BorrowedFloat32Memory(const_cast<float*>(volume)));
	astra::CFloat32ProjectionData3D sinogram_data(
	    projection_geometry, new BorrowedFloat32Memory(sinogram));

	if (volume_data.getFloat32Memory() != volume) {
		g_last_error = "3D volume buffer was not borrowed zero-copy";
		return false;
	}
	if (sinogram_data.getFloat32Memory() != sinogram) {
		g_last_error = "3D sinogram buffer was not borrowed zero-copy";
		return false;
	}

	astra::CCompositeGeometryManager cgm;
	if (gpu_index >= 0) {
		cgm.setGPUIndices(std::vector<int>{gpu_index});
	}
	if (!cgm.doFP(nullptr, &volume_data, &sinogram_data, astra::CCompositeGeometryManager::MODE_SET)) {
		g_last_error = "3D CUDA forward projection run failed";
		return false;
	}
	return true;
}

#endif

struct VolumeWindow2DState {
	bool active = false;
	float min_x = 0.0f;
	float min_y = 0.0f;
	float max_x = 0.0f;
	float max_y = 0.0f;
};
static thread_local VolumeWindow2DState g_thread_vol_window_2d;

struct VolumeWindow3DState {
	bool active = false;
	float min_x = 0.0f;
	float min_y = 0.0f;
	float min_z = 0.0f;
	float max_x = 0.0f;
	float max_y = 0.0f;
	float max_z = 0.0f;
};
static thread_local VolumeWindow3DState g_thread_vol_window_3d;

static void init_volume_geometry_2d(astra::CVolumeGeometry2D& geom, int width, int height) {
	if (g_thread_vol_window_2d.active) {
		geom.initialize(
		    width, height,
		    g_thread_vol_window_2d.min_x, g_thread_vol_window_2d.min_y,
		    g_thread_vol_window_2d.max_x, g_thread_vol_window_2d.max_y);
	} else {
		geom.initialize(width, height);
	}
}

static void init_volume_geometry_3d(astra::CVolumeGeometry3D& geom, int width, int height, int depth) {
	if (g_thread_vol_window_3d.active) {
		geom.initialize(
		    width, height, depth,
		    g_thread_vol_window_3d.min_x, g_thread_vol_window_3d.min_y, g_thread_vol_window_3d.min_z,
		    g_thread_vol_window_3d.max_x, g_thread_vol_window_3d.max_y, g_thread_vol_window_3d.max_z);
	} else {
		geom.initialize(width, height, depth);
	}
}

extern "C" int astra_julia_set_volume_window_2d(float min_x, float min_y, float max_x, float max_y) {
	if (min_x >= max_x || min_y >= max_y) {
		g_last_error = "invalid 2D volume window bounds (min must be < max)";
		return 0;
	}
	g_thread_vol_window_2d.active = true;
	g_thread_vol_window_2d.min_x = min_x;
	g_thread_vol_window_2d.min_y = min_y;
	g_thread_vol_window_2d.max_x = max_x;
	g_thread_vol_window_2d.max_y = max_y;
	return 1;
}

extern "C" int astra_julia_clear_volume_window_2d(void) {
	g_thread_vol_window_2d.active = false;
	return 1;
}

extern "C" int astra_julia_get_volume_window_2d(float* window_out) {
	if (!window_out) return 0;
	if (!g_thread_vol_window_2d.active) return 0;
	window_out[0] = g_thread_vol_window_2d.min_x;
	window_out[1] = g_thread_vol_window_2d.min_y;
	window_out[2] = g_thread_vol_window_2d.max_x;
	window_out[3] = g_thread_vol_window_2d.max_y;
	return 1;
}

extern "C" int astra_julia_set_volume_window_3d(float min_x, float min_y, float min_z, float max_x, float max_y, float max_z) {
	if (min_x >= max_x || min_y >= max_y || min_z >= max_z) {
		g_last_error = "invalid 3D volume window bounds (min must be < max)";
		return 0;
	}
	g_thread_vol_window_3d.active = true;
	g_thread_vol_window_3d.min_x = min_x;
	g_thread_vol_window_3d.min_y = min_y;
	g_thread_vol_window_3d.min_z = min_z;
	g_thread_vol_window_3d.max_x = max_x;
	g_thread_vol_window_3d.max_y = max_y;
	g_thread_vol_window_3d.max_z = max_z;
	return 1;
}

extern "C" int astra_julia_clear_volume_window_3d(void) {
	g_thread_vol_window_3d.active = false;
	return 1;
}

extern "C" int astra_julia_get_volume_window_3d(float* window_out) {
	if (!window_out) return 0;
	if (!g_thread_vol_window_3d.active) return 0;
	window_out[0] = g_thread_vol_window_3d.min_x;
	window_out[1] = g_thread_vol_window_3d.min_y;
	window_out[2] = g_thread_vol_window_3d.min_z;
	window_out[3] = g_thread_vol_window_3d.max_x;
	window_out[4] = g_thread_vol_window_3d.max_y;
	window_out[5] = g_thread_vol_window_3d.max_z;
	return 1;
}

std::unique_ptr<astra::CProjector2D> create_cpu_projector_2d(
    const astra::CVolumeGeometry2D& volume_geometry,
    const astra::CProjectionGeometry2D& projection_geometry,
    int projector_kernel,
    const char* geom_type,
    int angle_count,
    int detector_count,
    const float* vectors)
{
	if (std::strcmp(geom_type, "parallel") == 0) {
		const auto& par_geom = dynamic_cast<const astra::CParallelProjectionGeometry2D&>(projection_geometry);
		if (projector_kernel == 0) {
			auto proj = std::make_unique<astra::CParallelBeamLineKernelProjector2D>(par_geom, volume_geometry);
			if (!proj->isInitialized()) {
				g_last_error = "failed to initialize parallel line projector";
				return nullptr;
			}
			return proj;
		} else if (projector_kernel == 1) {
			auto proj = std::make_unique<astra::CParallelBeamLinearKernelProjector2D>(par_geom, volume_geometry);
			if (!proj->isInitialized()) {
				g_last_error = "failed to initialize parallel linear projector";
				return nullptr;
			}
			return proj;
		} else if (projector_kernel == 2) {
			auto proj = std::make_unique<astra::CParallelBeamStripKernelProjector2D>(par_geom, volume_geometry);
			if (!proj->isInitialized()) {
				g_last_error = "failed to initialize parallel strip projector";
				return nullptr;
			}
			return proj;
		} else if (projector_kernel == 3) {
			auto proj = std::make_unique<astra::CParallelBeamDistanceDrivenProjector2D>(par_geom, volume_geometry);
			if (!proj->isInitialized()) {
				g_last_error = "failed to initialize parallel distance-driven projector";
				return nullptr;
			}
			return proj;
		}
	} else if (std::strcmp(geom_type, "parallel_vec") == 0) {
		astra::XMLConfig projector_config("Projector2D");
		fill_vec_projection_config_node(projector_config.self.addChildNode("ProjectionGeometry"), "parallel_vec", angle_count, detector_count, vectors);
		fill_volume_geometry_config_node(projector_config.self.addChildNode("VolumeGeometry"), volume_geometry);
		if (projector_kernel == 0) {
			auto proj = std::make_unique<astra::CParallelBeamLineKernelProjector2D>();
			if (!proj->initialize(projector_config)) {
				g_last_error = "failed to initialize parallel vec line projector";
				return nullptr;
			}
			return proj;
		} else if (projector_kernel == 1) {
			auto proj = std::make_unique<astra::CParallelBeamLinearKernelProjector2D>();
			if (!proj->initialize(projector_config)) {
				g_last_error = "failed to initialize parallel vec linear projector";
				return nullptr;
			}
			return proj;
		} else if (projector_kernel == 2) {
			auto proj = std::make_unique<astra::CParallelBeamStripKernelProjector2D>();
			if (!proj->initialize(projector_config)) {
				g_last_error = "failed to initialize parallel vec strip projector";
				return nullptr;
			}
			return proj;
		} else if (projector_kernel == 3) {
			auto proj = std::make_unique<astra::CParallelBeamDistanceDrivenProjector2D>();
			if (!proj->initialize(projector_config)) {
				g_last_error = "failed to initialize parallel vec distance-driven projector";
				return nullptr;
			}
			return proj;
		}
	} else if (std::strcmp(geom_type, "fanflat") == 0) {
		const auto& fan_geom = dynamic_cast<const astra::CFanFlatProjectionGeometry2D&>(projection_geometry);
		if (projector_kernel == 0) {
			auto proj = std::make_unique<astra::CFanFlatBeamLineKernelProjector2D>(fan_geom, volume_geometry);
			if (!proj->isInitialized()) {
				g_last_error = "failed to initialize fanflat line projector";
				return nullptr;
			}
			return proj;
		} else if (projector_kernel == 1) {
			g_last_error = "linear kernel projector is only supported for parallel beam";
			return nullptr;
		} else if (projector_kernel == 2) {
			auto proj = std::make_unique<astra::CFanFlatBeamStripKernelProjector2D>(fan_geom, volume_geometry);
			if (!proj->isInitialized()) {
				g_last_error = "failed to initialize fanflat strip projector";
				return nullptr;
			}
			return proj;
		} else if (projector_kernel == 3) {
			g_last_error = "distance-driven projector is only supported for parallel beam";
			return nullptr;
		}
	} else if (std::strcmp(geom_type, "fanflat_vec") == 0) {
		if (projector_kernel == 0) {
			astra::XMLConfig projector_config("Projector2D");
			fill_vec_projection_config_node(projector_config.self.addChildNode("ProjectionGeometry"), "fanflat_vec", angle_count, detector_count, vectors);
			fill_volume_geometry_config_node(projector_config.self.addChildNode("VolumeGeometry"), volume_geometry);
			auto proj = std::make_unique<astra::CFanFlatBeamLineKernelProjector2D>();
			if (!proj->initialize(projector_config)) {
				g_last_error = "failed to initialize fanflat vec line projector";
				return nullptr;
			}
			return proj;
		} else {
			g_last_error = "only line projector is supported for fanflat_vec on CPU";
			return nullptr;
		}
	}
	g_last_error = "unsupported geometry or projector combination";
	return nullptr;
}

bool run_cpu_fp_2d(astra::CVolumeGeometry2D& volume_geometry,
                   const astra::CProjectionGeometry2D& projection_geometry,
                   astra::CProjector2D* projector,
                   const float* volume,
                   float* sinogram)
{
	astra::CFloat32VolumeData2D volume_data(
	    volume_geometry, new BorrowedFloat32Memory(const_cast<float*>(volume)));
	astra::CFloat32ProjectionData2D sinogram_data(
	    projection_geometry, new BorrowedFloat32Memory(sinogram));

	if (volume_data.getFloat32Memory() != volume) {
		g_last_error = "volume buffer was not borrowed zero-copy";
		return false;
	}
	if (sinogram_data.getFloat32Memory() != sinogram) {
		g_last_error = "sinogram buffer was not borrowed zero-copy";
		return false;
	}
	astra::CForwardProjectionAlgorithm algorithm;
	if (!algorithm.initialize(projector, &volume_data, &sinogram_data)) {
		g_last_error = "failed to initialize forward projection algorithm";
		return false;
	}
	if (!algorithm.run()) {
		g_last_error = "forward projection run failed";
		return false;
	}
	return true;
}

bool run_cpu_bp_2d(astra::CVolumeGeometry2D& volume_geometry,
                   const astra::CProjectionGeometry2D& projection_geometry,
                   astra::CProjector2D* projector,
                   const float* sinogram,
                   float* volume)
{
	astra::CFloat32VolumeData2D volume_data(
	    volume_geometry, new BorrowedFloat32Memory(volume));
	astra::CFloat32ProjectionData2D sinogram_data(
	    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));

	if (volume_data.getFloat32Memory() != volume) {
		g_last_error = "volume buffer was not borrowed zero-copy";
		return false;
	}
	if (sinogram_data.getFloat32Memory() != sinogram) {
		g_last_error = "sinogram buffer was not borrowed zero-copy";
		return false;
	}
	astra::CBackProjectionAlgorithm algorithm;
	if (!algorithm.initialize(projector, &sinogram_data, &volume_data)) {
		g_last_error = "failed to initialize backprojection algorithm";
		return false;
	}
	if (!algorithm.run()) {
		g_last_error = "backprojection run failed";
		return false;
	}
	return true;
}

bool run_cpu_sirt_2d(astra::CVolumeGeometry2D& volume_geometry,
                     const astra::CProjectionGeometry2D& projection_geometry,
                     astra::CProjector2D* projector,
                     const float* sinogram,
                     float* volume,
                     int iterations,
                     float relaxation,
                     const float* reconstruction_mask,
                     const float* sinogram_mask,
                     bool use_min_constraint,
                     float min_constraint,
                     bool use_max_constraint,
                     float max_constraint)
{
	BorrowedSirtAlgorithm algorithm;
	astra::CFloat32VolumeData2D volume_data(
	    volume_geometry, new BorrowedFloat32Memory(volume));
	astra::CFloat32ProjectionData2D sinogram_data(
	    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));
	std::unique_ptr<astra::CFloat32VolumeData2D> reconstruction_mask_data;
	std::unique_ptr<astra::CFloat32ProjectionData2D> sinogram_mask_data;

	if (volume_data.getFloat32Memory() != volume) {
		g_last_error = "volume buffer was not borrowed zero-copy";
		return false;
	}
	if (sinogram_data.getFloat32Memory() != sinogram) {
		g_last_error = "sinogram buffer was not borrowed zero-copy";
		return false;
	}
	if (!algorithm.initializeWithOptions(
	        projector,
	        &sinogram_data,
	        &volume_data,
	        relaxation,
	        use_min_constraint ? 1 : 0,
	        min_constraint,
	        use_max_constraint ? 1 : 0,
	        max_constraint)) {
		g_last_error = "failed to initialize CPU SIRT algorithm";
		return false;
	}
	if (reconstruction_mask) {
		reconstruction_mask_data = std::make_unique<astra::CFloat32VolumeData2D>(
		    volume_geometry, new BorrowedFloat32Memory(const_cast<float*>(reconstruction_mask)));
		algorithm.setReconstructionMask(reconstruction_mask_data.get());
	}
	if (sinogram_mask) {
		sinogram_mask_data = std::make_unique<astra::CFloat32ProjectionData2D>(
		    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram_mask)));
		algorithm.setSinogramMask(sinogram_mask_data.get());
	}
	if (!algorithm.run(iterations)) {
		g_last_error = "CPU SIRT run failed";
		return false;
	}
	return true;
}

bool run_cpu_sart_2d(astra::CVolumeGeometry2D& volume_geometry,
                     const astra::CProjectionGeometry2D& projection_geometry,
                     astra::CProjector2D* projector,
                     const float* sinogram,
                     float* volume,
                     int iterations,
                     float relaxation,
                     int projection_order_mode,
                     const int* projection_order,
                     int projection_order_length,
                     int angle_count,
                     const float* reconstruction_mask,
                     const float* sinogram_mask,
                     bool use_min_constraint,
                     float min_constraint,
                     bool use_max_constraint,
                     float max_constraint)
{
	BorrowedSartAlgorithm algorithm;
	astra::CFloat32VolumeData2D volume_data(
	    volume_geometry, new BorrowedFloat32Memory(volume));
	astra::CFloat32ProjectionData2D sinogram_data(
	    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));
	std::unique_ptr<astra::CFloat32VolumeData2D> reconstruction_mask_data;
	std::unique_ptr<astra::CFloat32ProjectionData2D> sinogram_mask_data;

	if (volume_data.getFloat32Memory() != volume) {
		g_last_error = "volume buffer was not borrowed zero-copy";
		return false;
	}
	if (sinogram_data.getFloat32Memory() != sinogram) {
		g_last_error = "sinogram buffer was not borrowed zero-copy";
		return false;
	}
	std::vector<int> order;
	if (projection_order_mode == 1) {
		order.resize(angle_count);
		for (int i = 0; i < angle_count; ++i) {
			order[i] = i;
		}
	} else if (projection_order_mode == 0) {
		order.resize(angle_count);
		for (int i = 0; i < angle_count; ++i) {
			order[i] = i;
		}
		for (int i = 0; i < angle_count - 1; ++i) {
			const int k = std::rand() % (angle_count - i);
			const int t = order[i];
			order[i] = order[i + k];
			order[i + k] = t;
		}
	} else {
		order.assign(projection_order, projection_order + projection_order_length);
	}

	if (!algorithm.initializeWithOptions(
	        projector,
	        &sinogram_data,
	        &volume_data,
	        relaxation,
	        order.data(),
	        static_cast<int>(order.size()),
	        use_min_constraint ? 1 : 0,
	        min_constraint,
	        use_max_constraint ? 1 : 0,
	        max_constraint)) {
		g_last_error = "failed to initialize CPU SART algorithm";
		return false;
	}
	if (reconstruction_mask) {
		reconstruction_mask_data = std::make_unique<astra::CFloat32VolumeData2D>(
		    volume_geometry, new BorrowedFloat32Memory(const_cast<float*>(reconstruction_mask)));
		algorithm.setReconstructionMask(reconstruction_mask_data.get());
	}
	if (sinogram_mask) {
		sinogram_mask_data = std::make_unique<astra::CFloat32ProjectionData2D>(
		    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram_mask)));
		algorithm.setSinogramMask(sinogram_mask_data.get());
	}
	if (!algorithm.run(iterations)) {
		g_last_error = "CPU SART run failed";
		return false;
	}
	return true;
}

bool run_cpu_cgls_2d(astra::CVolumeGeometry2D& volume_geometry,
                     const astra::CProjectionGeometry2D& projection_geometry,
                     astra::CProjector2D* projector,
                     const float* sinogram,
                     float* volume,
                     int iterations,
                     const float* reconstruction_mask,
                     const float* sinogram_mask,
                     bool use_min_constraint,
                     float min_constraint,
                     bool use_max_constraint,
                     float max_constraint)
{
	BorrowedCglsAlgorithm algorithm;
	astra::CFloat32VolumeData2D volume_data(
	    volume_geometry, new BorrowedFloat32Memory(volume));
	astra::CFloat32ProjectionData2D sinogram_data(
	    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));
	std::unique_ptr<astra::CFloat32VolumeData2D> reconstruction_mask_data;
	std::unique_ptr<astra::CFloat32ProjectionData2D> sinogram_mask_data;

	if (volume_data.getFloat32Memory() != volume) {
		g_last_error = "volume buffer was not borrowed zero-copy";
		return false;
	}
	if (sinogram_data.getFloat32Memory() != sinogram) {
		g_last_error = "sinogram buffer was not borrowed zero-copy";
		return false;
	}
	if (!algorithm.initializeWithOptions(
	        projector,
	        &sinogram_data,
	        &volume_data,
	        use_min_constraint ? 1 : 0,
	        min_constraint,
	        use_max_constraint ? 1 : 0,
	        max_constraint)) {
		g_last_error = "failed to initialize CPU CGLS algorithm";
		return false;
	}
	if (reconstruction_mask) {
		reconstruction_mask_data = std::make_unique<astra::CFloat32VolumeData2D>(
		    volume_geometry, new BorrowedFloat32Memory(const_cast<float*>(reconstruction_mask)));
		algorithm.setReconstructionMask(reconstruction_mask_data.get());
	}
	if (sinogram_mask) {
		sinogram_mask_data = std::make_unique<astra::CFloat32ProjectionData2D>(
		    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram_mask)));
		algorithm.setSinogramMask(sinogram_mask_data.get());
	}
	if (!algorithm.run(iterations)) {
		g_last_error = "CPU CGLS run failed";
		return false;
	}
	return true;
}

bool run_cpu_art_2d(astra::CVolumeGeometry2D& volume_geometry,
                    const astra::CProjectionGeometry2D& projection_geometry,
                    astra::CProjector2D* projector,
                    const float* sinogram,
                    float* volume,
                    int iterations,
                    float relaxation,
                    const float* reconstruction_mask,
                    const float* sinogram_mask,
                    bool use_min_constraint,
                    float min_constraint,
                    bool use_max_constraint,
                    float max_constraint)
{
	BorrowedArtAlgorithm algorithm;
	astra::CFloat32VolumeData2D volume_data(
	    volume_geometry, new BorrowedFloat32Memory(volume));
	astra::CFloat32ProjectionData2D sinogram_data(
	    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));
	std::unique_ptr<astra::CFloat32VolumeData2D> reconstruction_mask_data;
	std::unique_ptr<astra::CFloat32ProjectionData2D> sinogram_mask_data;

	if (volume_data.getFloat32Memory() != volume) {
		g_last_error = "volume buffer was not borrowed zero-copy";
		return false;
	}
	if (sinogram_data.getFloat32Memory() != sinogram) {
		g_last_error = "sinogram buffer was not borrowed zero-copy";
		return false;
	}
	if (!algorithm.initializeWithOptions(
	        projector,
	        &sinogram_data,
	        &volume_data,
	        relaxation,
	        use_min_constraint ? 1 : 0,
	        min_constraint,
	        use_max_constraint ? 1 : 0,
	        max_constraint)) {
		g_last_error = "failed to initialize CPU ART algorithm";
		return false;
	}
	if (reconstruction_mask) {
		reconstruction_mask_data = std::make_unique<astra::CFloat32VolumeData2D>(
		    volume_geometry, new BorrowedFloat32Memory(const_cast<float*>(reconstruction_mask)));
		algorithm.setReconstructionMask(reconstruction_mask_data.get());
	}
	if (sinogram_mask) {
		sinogram_mask_data = std::make_unique<astra::CFloat32ProjectionData2D>(
		    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram_mask)));
		algorithm.setSinogramMask(sinogram_mask_data.get());
	}
	if (!algorithm.run(iterations)) {
		g_last_error = "CPU ART run failed";
		return false;
	}
	return true;
}

} // namespace

extern "C" int astra_julia_fp2d_parallel_line_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    float* volume,
    float* sinogram)
{
	g_last_error.clear();

	if (!validate_inputs(volume_width,
	                     volume_height,
	                     angle_count,
	                     detector_count,
	                     detector_width,
	                     angles,
	                     volume,
	                     sinogram)) {
		return 0;
	}

	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize projection geometry";
			return 0;
		}

		astra::CFloat32VolumeData2D volume_data(
		    volume_geometry, new BorrowedFloat32Memory(volume));
		astra::CFloat32ProjectionData2D sinogram_data(
		    projection_geometry, new BorrowedFloat32Memory(sinogram));

		if (volume_data.getFloat32Memory() != volume) {
			g_last_error = "volume buffer was not borrowed zero-copy";
			return 0;
		}
		if (sinogram_data.getFloat32Memory() != sinogram) {
			g_last_error = "sinogram buffer was not borrowed zero-copy";
			return 0;
		}

		astra::CParallelBeamLineKernelProjector2D projector(
		    projection_geometry, volume_geometry);
		if (!projector.isInitialized()) {
			g_last_error = "failed to initialize parallel line projector";
			return 0;
		}

		astra::CForwardProjectionAlgorithm algorithm;
		if (!algorithm.initialize(&projector, &volume_data, &sinogram_data)) {
			g_last_error = "failed to initialize forward projection algorithm";
			return 0;
		}
		if (!algorithm.run()) {
			g_last_error = "forward projection run failed";
			return 0;
		}

		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
}

extern "C" int astra_julia_cuda_fp2d_parallel_line_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    const float* volume,
    float* sinogram,
    int detector_supersampling,
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_inputs(volume_width,
	                     volume_height,
	                     angle_count,
	                     detector_count,
	                     detector_width,
	                     angles,
	                     const_cast<float*>(volume),
	                     sinogram) ||
	    !validate_detector_supersampling(detector_supersampling)) {
		return 0;
	}

	if (gpu_index < -1) {
		g_last_error = "gpu_index must be >= -1";
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize projection geometry";
			return 0;
		}

		astraCUDA::SParProjection* par_projections = nullptr;
		astraCUDA::SFanProjection* fan_projections = nullptr;
		float output_scale = 1.0f;
		const bool ok_geometry = astra::convertAstraGeometry(
		    &volume_geometry,
		    static_cast<const astra::CProjectionGeometry2D*>(&projection_geometry),
		    par_projections,
		    fan_projections,
		    output_scale);
		if (!ok_geometry) {
			g_last_error = "failed to convert ASTRA geometry for CUDA";
			return 0;
		}
		if (!par_projections || fan_projections) {
			delete[] par_projections;
			delete[] fan_projections;
			g_last_error = "unexpected CUDA geometry conversion result";
			return 0;
		}

		const bool ok = astra::astraCudaFP(
		    volume,
		    sinogram,
		    static_cast<unsigned int>(volume_width),
		    static_cast<unsigned int>(volume_height),
		    static_cast<unsigned int>(angle_count),
		    static_cast<unsigned int>(detector_count),
		    par_projections,
		    static_cast<unsigned int>(detector_supersampling),
		    output_scale,
		    gpu_index);
		delete[] par_projections;

		if (!ok) {
			g_last_error = "astraCudaFP failed";
			return 0;
		}
		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)angle_count;
	(void)detector_count;
	(void)detector_width;
	(void)angles;
	(void)volume;
	(void)sinogram;
	(void)detector_supersampling;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_bp2d_parallel_line_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    const float* angles,
    const float* sinogram,
    float* volume)
{
	g_last_error.clear();

	if (!validate_inputs(volume_width,
	                     volume_height,
	                     angle_count,
	                     detector_count,
	                     detector_width,
	                     angles,
	                     volume,
	                     const_cast<float*>(sinogram))) {
		return 0;
	}

	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize projection geometry";
			return 0;
		}

		astra::CFloat32VolumeData2D volume_data(
		    volume_geometry, new BorrowedFloat32Memory(volume));
		astra::CFloat32ProjectionData2D sinogram_data(
		    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));

		if (volume_data.getFloat32Memory() != volume) {
			g_last_error = "volume buffer was not borrowed zero-copy";
			return 0;
		}
		if (sinogram_data.getFloat32Memory() != sinogram) {
			g_last_error = "sinogram buffer was not borrowed zero-copy";
			return 0;
		}

		astra::CParallelBeamLineKernelProjector2D projector(
		    projection_geometry, volume_geometry);
		if (!projector.isInitialized()) {
			g_last_error = "failed to initialize parallel line projector";
			return 0;
		}

		astra::CBackProjectionAlgorithm algorithm;
		if (!algorithm.initialize(&projector, &sinogram_data, &volume_data)) {
			g_last_error = "failed to initialize backprojection algorithm";
			return 0;
		}
		if (!algorithm.run()) {
			g_last_error = "backprojection run failed";
			return 0;
		}

		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
}

extern "C" int astra_julia_cuda_bp2d_parallel_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_inputs(volume_width,
	                     volume_height,
	                     angle_count,
	                     detector_count,
	                     detector_width,
	                     angles,
	                     volume,
	                     const_cast<float*>(sinogram))) {
		return 0;
	}

	if (!validate_detector_supersampling(detector_supersampling) ||
	    !validate_pixel_supersampling(pixel_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize projection geometry";
			return 0;
		}

		astra::CFloat32VolumeData2D volume_data(
		    volume_geometry, new BorrowedFloat32Memory(volume));
		astra::CFloat32ProjectionData2D sinogram_data(
		    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));

		if (volume_data.getFloat32Memory() != volume) {
			g_last_error = "volume buffer was not borrowed zero-copy";
			return 0;
		}
		if (sinogram_data.getFloat32Memory() != sinogram) {
			g_last_error = "sinogram buffer was not borrowed zero-copy";
			return 0;
		}

		BorrowedCudaBackProjectionAlgorithm algorithm;
		if (!algorithm.initializeWithOptions(
		        &sinogram_data,
		        &volume_data,
		        gpu_index,
		        detector_supersampling,
		        pixel_supersampling)) {
			g_last_error = "failed to initialize CUDA backprojection algorithm";
			return 0;
		}
		if (!algorithm.run(1)) {
			g_last_error = "CUDA backprojection run failed";
			return 0;
		}

		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)angle_count;
	(void)detector_count;
	(void)detector_width;
	(void)angles;
	(void)sinogram;
	(void)volume;
	(void)detector_supersampling;
	(void)pixel_supersampling;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_fp2d_parallel_vec_line_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    float* volume,
    float* sinogram)
{
	g_last_error.clear();

	if (!validate_vec_inputs_2d(volume_width,
	                            volume_height,
	                            angle_count,
	                            detector_count,
	                            vectors,
	                            volume,
	                            sinogram)) {
		return 0;
	}

	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		astra::CParallelVecProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    build_parallel_vec_geometry_2d(angle_count, detector_count, vectors));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize parallel vec projection geometry";
			return 0;
		}

		astra::CFloat32VolumeData2D volume_data(
		    volume_geometry, new BorrowedFloat32Memory(volume));
		astra::CFloat32ProjectionData2D sinogram_data(
		    projection_geometry, new BorrowedFloat32Memory(sinogram));

		if (volume_data.getFloat32Memory() != volume) {
			g_last_error = "volume buffer was not borrowed zero-copy";
			return 0;
		}
		if (sinogram_data.getFloat32Memory() != sinogram) {
			g_last_error = "sinogram buffer was not borrowed zero-copy";
			return 0;
		}

		astra::XMLConfig projector_config("Projector2D");
		fill_vec_projection_config_node(projector_config.self.addChildNode("ProjectionGeometry"), "parallel_vec", angle_count, detector_count, vectors);
		fill_volume_geometry_config_node(projector_config.self.addChildNode("VolumeGeometry"), volume_geometry);

		astra::CParallelBeamLineKernelProjector2D projector;
		if (!projector.initialize(projector_config)) {
			g_last_error = "failed to initialize parallel vec line projector";
			return 0;
		}

		astra::CForwardProjectionAlgorithm algorithm;
		if (!algorithm.initialize(&projector, &volume_data, &sinogram_data)) {
			g_last_error = "failed to initialize forward projection algorithm";
			return 0;
		}
		if (!algorithm.run()) {
			g_last_error = "forward projection run failed";
			return 0;
		}

		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
}

extern "C" int astra_julia_cuda_fp2d_parallel_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* volume,
    float* sinogram,
    int detector_supersampling,
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_2d(volume_width,
	                            volume_height,
	                            angle_count,
	                            detector_count,
	                            vectors,
	                            volume,
	                            sinogram) ||
	    !validate_detector_supersampling(detector_supersampling)) {
		return 0;
	}

	if (gpu_index < -1) {
		g_last_error = "gpu_index must be >= -1";
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		astra::CParallelVecProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    build_parallel_vec_geometry_2d(angle_count, detector_count, vectors));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize parallel vec projection geometry";
			return 0;
		}

		astraCUDA::SParProjection* par_projections = nullptr;
		float output_scale = 1.0f;
		const bool ok_geometry = astra::convertAstraGeometry(
		    &volume_geometry,
		    &projection_geometry,
		    par_projections,
		    output_scale);
		if (!ok_geometry) {
			g_last_error = "failed to convert ASTRA parallel vec geometry for CUDA";
			return 0;
		}
		if (!par_projections) {
			g_last_error = "CUDA parallel vec geometry conversion returned null";
			return 0;
		}

		const bool ok = astra::astraCudaFP(
		    volume,
		    sinogram,
		    static_cast<unsigned int>(volume_width),
		    static_cast<unsigned int>(volume_height),
		    static_cast<unsigned int>(angle_count),
		    static_cast<unsigned int>(detector_count),
		    par_projections,
		    static_cast<unsigned int>(detector_supersampling),
		    output_scale,
		    gpu_index);
		delete[] par_projections;

		if (!ok) {
			g_last_error = "astraCudaFP failed for parallel_vec";
			return 0;
		}
		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)angle_count;
	(void)detector_count;
	(void)vectors;
	(void)volume;
	(void)sinogram;
	(void)detector_supersampling;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_bp2d_parallel_vec_line_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume)
{
	g_last_error.clear();

	if (!validate_vec_inputs_2d(volume_width,
	                            volume_height,
	                            angle_count,
	                            detector_count,
	                            vectors,
	                            sinogram,
	                            volume)) {
		return 0;
	}

	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		astra::CParallelVecProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    build_parallel_vec_geometry_2d(angle_count, detector_count, vectors));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize parallel vec projection geometry";
			return 0;
		}

		astra::CFloat32VolumeData2D volume_data(
		    volume_geometry, new BorrowedFloat32Memory(volume));
		astra::CFloat32ProjectionData2D sinogram_data(
		    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));

		if (volume_data.getFloat32Memory() != volume) {
			g_last_error = "volume buffer was not borrowed zero-copy";
			return 0;
		}
		if (sinogram_data.getFloat32Memory() != sinogram) {
			g_last_error = "sinogram buffer was not borrowed zero-copy";
			return 0;
		}

		astra::XMLConfig projector_config("Projector2D");
		fill_vec_projection_config_node(projector_config.self.addChildNode("ProjectionGeometry"), "parallel_vec", angle_count, detector_count, vectors);
		fill_volume_geometry_config_node(projector_config.self.addChildNode("VolumeGeometry"), volume_geometry);

		astra::CParallelBeamLineKernelProjector2D projector;
		if (!projector.initialize(projector_config)) {
			g_last_error = "failed to initialize parallel vec line projector";
			return 0;
		}

		astra::CBackProjectionAlgorithm algorithm;
		if (!algorithm.initialize(&projector, &sinogram_data, &volume_data)) {
			g_last_error = "failed to initialize backprojection algorithm";
			return 0;
		}
		if (!algorithm.run()) {
			g_last_error = "backprojection run failed";
			return 0;
		}

		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
}

extern "C" int astra_julia_cuda_bp2d_parallel_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int detector_supersampling,
    int pixel_supersampling,
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_2d(volume_width,
	                            volume_height,
	                            angle_count,
	                            detector_count,
	                            vectors,
	                            sinogram,
	                            volume)) {
		return 0;
	}

	if (!validate_detector_supersampling(detector_supersampling) ||
	    !validate_pixel_supersampling(pixel_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		astra::CParallelVecProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    build_parallel_vec_geometry_2d(angle_count, detector_count, vectors));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize parallel vec projection geometry";
			return 0;
		}

		astra::CFloat32VolumeData2D volume_data(
		    volume_geometry, new BorrowedFloat32Memory(volume));
		astra::CFloat32ProjectionData2D sinogram_data(
		    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));

		if (volume_data.getFloat32Memory() != volume) {
			g_last_error = "volume buffer was not borrowed zero-copy";
			return 0;
		}
		if (sinogram_data.getFloat32Memory() != sinogram) {
			g_last_error = "sinogram buffer was not borrowed zero-copy";
			return 0;
		}

		BorrowedCudaBackProjectionAlgorithm algorithm;
		if (!algorithm.initializeWithOptions(
		        &sinogram_data,
		        &volume_data,
		        gpu_index,
		        detector_supersampling,
		        pixel_supersampling)) {
			g_last_error = "failed to initialize CUDA backprojection algorithm";
			return 0;
		}
		if (!algorithm.run(1)) {
			g_last_error = "CUDA backprojection run failed";
			return 0;
		}

		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)angle_count;
	(void)detector_count;
	(void)vectors;
	(void)sinogram;
	(void)volume;
	(void)detector_supersampling;
	(void)pixel_supersampling;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_fp2d_fanflat_line_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    float origin_source_distance,
    float origin_detector_distance,
    const float* angles,
    float* volume,
    float* sinogram)
{
	g_last_error.clear();

	if (!validate_inputs(volume_width,
	                     volume_height,
	                     angle_count,
	                     detector_count,
	                     detector_width,
	                     angles,
	                     volume,
	                     sinogram) ||
	    !validate_fanflat_distances(origin_source_distance,
	                                origin_detector_distance)) {
		return 0;
	}

	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CFanFlatProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    detector_width,
		    std::move(angle_vector),
		    origin_source_distance,
		    origin_detector_distance);

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize fanflat projection geometry";
			return 0;
		}

		astra::CFloat32VolumeData2D volume_data(
		    volume_geometry, new BorrowedFloat32Memory(volume));
		astra::CFloat32ProjectionData2D sinogram_data(
		    projection_geometry, new BorrowedFloat32Memory(sinogram));

		if (volume_data.getFloat32Memory() != volume) {
			g_last_error = "volume buffer was not borrowed zero-copy";
			return 0;
		}
		if (sinogram_data.getFloat32Memory() != sinogram) {
			g_last_error = "sinogram buffer was not borrowed zero-copy";
			return 0;
		}

		astra::CFanFlatBeamLineKernelProjector2D projector(
		    projection_geometry, volume_geometry);
		if (!projector.isInitialized()) {
			g_last_error = "failed to initialize fanflat line projector";
			return 0;
		}

		astra::CForwardProjectionAlgorithm algorithm;
		if (!algorithm.initialize(&projector, &volume_data, &sinogram_data)) {
			g_last_error = "failed to initialize forward projection algorithm";
			return 0;
		}
		if (!algorithm.run()) {
			g_last_error = "forward projection run failed";
			return 0;
		}

		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
}

extern "C" int astra_julia_bp2d_fanflat_line_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    float detector_width,
    float origin_source_distance,
    float origin_detector_distance,
    const float* angles,
    const float* sinogram,
    float* volume)
{
	g_last_error.clear();

	if (!validate_inputs(volume_width,
	                     volume_height,
	                     angle_count,
	                     detector_count,
	                     detector_width,
	                     angles,
	                     volume,
	                     const_cast<float*>(sinogram)) ||
	    !validate_fanflat_distances(origin_source_distance, origin_detector_distance)) {
		return 0;
	}

	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CFanFlatProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    detector_width,
		    std::move(angle_vector),
		    origin_source_distance,
		    origin_detector_distance);

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize fanflat projection geometry";
			return 0;
		}

		astra::CFloat32VolumeData2D volume_data(
		    volume_geometry, new BorrowedFloat32Memory(volume));
		astra::CFloat32ProjectionData2D sinogram_data(
		    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));

		if (volume_data.getFloat32Memory() != volume) {
			g_last_error = "volume buffer was not borrowed zero-copy";
			return 0;
		}
		if (sinogram_data.getFloat32Memory() != sinogram) {
			g_last_error = "sinogram buffer was not borrowed zero-copy";
			return 0;
		}

		astra::CFanFlatBeamLineKernelProjector2D projector(
		    projection_geometry, volume_geometry);
		if (!projector.isInitialized()) {
			g_last_error = "failed to initialize fanflat line projector";
			return 0;
		}

		astra::CBackProjectionAlgorithm algorithm;
		if (!algorithm.initialize(&projector, &sinogram_data, &volume_data)) {
			g_last_error = "failed to initialize backprojection algorithm";
			return 0;
		}
		if (!algorithm.run()) {
			g_last_error = "backprojection run failed";
			return 0;
		}

		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
}

extern "C" int astra_julia_cuda_fp2d_fanflat_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_inputs(volume_width,
	                     volume_height,
	                     angle_count,
	                     detector_count,
	                     detector_width,
	                     angles,
	                     const_cast<float*>(volume),
	                     sinogram) ||
	    !validate_fanflat_distances(origin_source_distance,
	                                origin_detector_distance) ||
	    !validate_detector_supersampling(detector_supersampling)) {
		return 0;
	}

	if (gpu_index < -1) {
		g_last_error = "gpu_index must be >= -1";
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CFanFlatProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    detector_width,
		    std::move(angle_vector),
		    origin_source_distance,
		    origin_detector_distance);

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize fanflat projection geometry";
			return 0;
		}

		astraCUDA::SFanProjection* fan_projections = nullptr;
		float output_scale = 1.0f;
		const bool ok_geometry = astra::convertAstraGeometry(
		    &volume_geometry,
		    &projection_geometry,
		    fan_projections,
		    output_scale);
		if (!ok_geometry) {
			g_last_error = "failed to convert ASTRA fanflat geometry for CUDA";
			return 0;
		}
		if (!fan_projections) {
			g_last_error = "CUDA fanflat geometry conversion returned null";
			return 0;
		}

		const bool ok = astra::astraCudaFanFP(
		    volume,
		    sinogram,
		    static_cast<unsigned int>(volume_width),
		    static_cast<unsigned int>(volume_height),
		    static_cast<unsigned int>(angle_count),
		    static_cast<unsigned int>(detector_count),
		    fan_projections,
		    static_cast<unsigned int>(detector_supersampling),
		    output_scale,
		    gpu_index);
		delete[] fan_projections;

		if (!ok) {
			g_last_error = "astraCudaFanFP failed";
			return 0;
		}
		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)angle_count;
	(void)detector_count;
	(void)detector_width;
	(void)origin_source_distance;
	(void)origin_detector_distance;
	(void)angles;
	(void)volume;
	(void)sinogram;
	(void)detector_supersampling;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_bp2d_fanflat_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_inputs(volume_width,
	                     volume_height,
	                     angle_count,
	                     detector_count,
	                     detector_width,
	                     angles,
	                     volume,
	                     const_cast<float*>(sinogram)) ||
	    !validate_fanflat_distances(origin_source_distance, origin_detector_distance) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_pixel_supersampling(pixel_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CFanFlatProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    detector_width,
		    std::move(angle_vector),
		    origin_source_distance,
		    origin_detector_distance);

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize fanflat projection geometry";
			return 0;
		}

		astra::CFloat32VolumeData2D volume_data(
		    volume_geometry, new BorrowedFloat32Memory(volume));
		astra::CFloat32ProjectionData2D sinogram_data(
		    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));

		if (volume_data.getFloat32Memory() != volume) {
			g_last_error = "volume buffer was not borrowed zero-copy";
			return 0;
		}
		if (sinogram_data.getFloat32Memory() != sinogram) {
			g_last_error = "sinogram buffer was not borrowed zero-copy";
			return 0;
		}

		BorrowedCudaBackProjectionAlgorithm algorithm;
		if (!algorithm.initializeWithOptions(
		        &sinogram_data,
		        &volume_data,
		        gpu_index,
		        detector_supersampling,
		        pixel_supersampling)) {
			g_last_error = "failed to initialize CUDA backprojection algorithm";
			return 0;
		}
		if (!algorithm.run(1)) {
			g_last_error = "CUDA backprojection run failed";
			return 0;
		}

		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)angle_count;
	(void)detector_count;
	(void)detector_width;
	(void)origin_source_distance;
	(void)origin_detector_distance;
	(void)angles;
	(void)sinogram;
	(void)volume;
	(void)detector_supersampling;
	(void)pixel_supersampling;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_fp2d_fanflat_vec_line_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    float* volume,
    float* sinogram)
{
	g_last_error.clear();

	if (!validate_vec_inputs_2d(volume_width,
	                            volume_height,
	                            angle_count,
	                            detector_count,
	                            vectors,
	                            volume,
	                            sinogram)) {
		return 0;
	}

	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		astra::CFanFlatVecProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    build_fanflat_vec_geometry_2d(angle_count, detector_count, vectors));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize fanflat vec projection geometry";
			return 0;
		}

		astra::CFloat32VolumeData2D volume_data(
		    volume_geometry, new BorrowedFloat32Memory(volume));
		astra::CFloat32ProjectionData2D sinogram_data(
		    projection_geometry, new BorrowedFloat32Memory(sinogram));

		if (volume_data.getFloat32Memory() != volume) {
			g_last_error = "volume buffer was not borrowed zero-copy";
			return 0;
		}
		if (sinogram_data.getFloat32Memory() != sinogram) {
			g_last_error = "sinogram buffer was not borrowed zero-copy";
			return 0;
		}

		astra::XMLConfig projector_config("Projector2D");
		fill_vec_projection_config_node(projector_config.self.addChildNode("ProjectionGeometry"), "fanflat_vec", angle_count, detector_count, vectors);
		fill_volume_geometry_config_node(projector_config.self.addChildNode("VolumeGeometry"), volume_geometry);

		astra::CFanFlatBeamLineKernelProjector2D projector;
		if (!projector.initialize(projector_config)) {
			g_last_error = "failed to initialize fanflat vec line projector";
			return 0;
		}

		astra::CForwardProjectionAlgorithm algorithm;
		if (!algorithm.initialize(&projector, &volume_data, &sinogram_data)) {
			g_last_error = "failed to initialize forward projection algorithm";
			return 0;
		}
		if (!algorithm.run()) {
			g_last_error = "forward projection run failed";
			return 0;
		}

		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
}

extern "C" int astra_julia_cuda_fp2d_fanflat_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* volume,
    float* sinogram,
    int detector_supersampling,
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_2d(volume_width,
	                            volume_height,
	                            angle_count,
	                            detector_count,
	                            vectors,
	                            volume,
	                            sinogram) ||
	    !validate_detector_supersampling(detector_supersampling)) {
		return 0;
	}

	if (gpu_index < -1) {
		g_last_error = "gpu_index must be >= -1";
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		astra::CFanFlatVecProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    build_fanflat_vec_geometry_2d(angle_count, detector_count, vectors));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize fanflat vec projection geometry";
			return 0;
		}

		astraCUDA::SFanProjection* fan_projections = nullptr;
		float output_scale = 1.0f;
		const bool ok_geometry = astra::convertAstraGeometry(
		    &volume_geometry,
		    &projection_geometry,
		    fan_projections,
		    output_scale);
		if (!ok_geometry) {
			g_last_error = "failed to convert ASTRA fanflat vec geometry for CUDA";
			return 0;
		}
		if (!fan_projections) {
			g_last_error = "CUDA fanflat vec geometry conversion returned null";
			return 0;
		}

		const bool ok = astra::astraCudaFanFP(
		    volume,
		    sinogram,
		    static_cast<unsigned int>(volume_width),
		    static_cast<unsigned int>(volume_height),
		    static_cast<unsigned int>(angle_count),
		    static_cast<unsigned int>(detector_count),
		    fan_projections,
		    static_cast<unsigned int>(detector_supersampling),
		    output_scale,
		    gpu_index);
		delete[] fan_projections;

		if (!ok) {
			g_last_error = "astraCudaFanFP failed for fanflat_vec";
			return 0;
		}
		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)angle_count;
	(void)detector_count;
	(void)vectors;
	(void)volume;
	(void)sinogram;
	(void)detector_supersampling;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_bp2d_fanflat_vec_line_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume)
{
	g_last_error.clear();

	if (!validate_vec_inputs_2d(volume_width,
	                            volume_height,
	                            angle_count,
	                            detector_count,
	                            vectors,
	                            sinogram,
	                            volume)) {
		return 0;
	}

	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		astra::CFanFlatVecProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    build_fanflat_vec_geometry_2d(angle_count, detector_count, vectors));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize fanflat vec projection geometry";
			return 0;
		}

		astra::CFloat32VolumeData2D volume_data(
		    volume_geometry, new BorrowedFloat32Memory(volume));
		astra::CFloat32ProjectionData2D sinogram_data(
		    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));

		if (volume_data.getFloat32Memory() != volume) {
			g_last_error = "volume buffer was not borrowed zero-copy";
			return 0;
		}
		if (sinogram_data.getFloat32Memory() != sinogram) {
			g_last_error = "sinogram buffer was not borrowed zero-copy";
			return 0;
		}

		astra::XMLConfig projector_config("Projector2D");
		fill_vec_projection_config_node(projector_config.self.addChildNode("ProjectionGeometry"), "fanflat_vec", angle_count, detector_count, vectors);
		fill_volume_geometry_config_node(projector_config.self.addChildNode("VolumeGeometry"), volume_geometry);

		astra::CFanFlatBeamLineKernelProjector2D projector;
		if (!projector.initialize(projector_config)) {
			g_last_error = "failed to initialize fanflat vec line projector";
			return 0;
		}

		astra::CBackProjectionAlgorithm algorithm;
		if (!algorithm.initialize(&projector, &sinogram_data, &volume_data)) {
			g_last_error = "failed to initialize backprojection algorithm";
			return 0;
		}
		if (!algorithm.run()) {
			g_last_error = "backprojection run failed";
			return 0;
		}

		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
}

extern "C" int astra_julia_cuda_bp2d_fanflat_vec_f32(
    int volume_width,
    int volume_height,
    int angle_count,
    int detector_count,
    const float* vectors,
    const float* sinogram,
    float* volume,
    int detector_supersampling,
    int pixel_supersampling,
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_2d(volume_width,
	                            volume_height,
	                            angle_count,
	                            detector_count,
	                            vectors,
	                            sinogram,
	                            volume)) {
		return 0;
	}

	if (!validate_detector_supersampling(detector_supersampling) ||
	    !validate_pixel_supersampling(pixel_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		astra::CFanFlatVecProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    build_fanflat_vec_geometry_2d(angle_count, detector_count, vectors));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize fanflat vec projection geometry";
			return 0;
		}

		astra::CFloat32VolumeData2D volume_data(
		    volume_geometry, new BorrowedFloat32Memory(volume));
		astra::CFloat32ProjectionData2D sinogram_data(
		    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));

		if (volume_data.getFloat32Memory() != volume) {
			g_last_error = "volume buffer was not borrowed zero-copy";
			return 0;
		}
		if (sinogram_data.getFloat32Memory() != sinogram) {
			g_last_error = "sinogram buffer was not borrowed zero-copy";
			return 0;
		}

		BorrowedCudaBackProjectionAlgorithm algorithm;
		if (!algorithm.initializeWithOptions(
		        &sinogram_data,
		        &volume_data,
		        gpu_index,
		        detector_supersampling,
		        pixel_supersampling)) {
			g_last_error = "failed to initialize CUDA backprojection algorithm";
			return 0;
		}
		if (!algorithm.run(1)) {
			g_last_error = "CUDA backprojection run failed";
			return 0;
		}

		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)angle_count;
	(void)detector_count;
	(void)vectors;
	(void)sinogram;
	(void)volume;
	(void)detector_supersampling;
	(void)pixel_supersampling;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_fbp2d_parallel_f32(
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
    float filter_parameter)
{
	g_last_error.clear();

	if (!validate_inputs(volume_width,
	                     volume_height,
	                     angle_count,
	                     detector_count,
	                     detector_width,
	                     angles,
	                     volume,
	                     const_cast<float*>(sinogram)) ||
	    !validate_filter_inputs(
	        filter_type, custom_filter, custom_filter_width, custom_filter_height, filter_d)) {
		return 0;
	}

	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize projection geometry";
			return 0;
		}

		astra::CFloat32VolumeData2D volume_data(
		    volume_geometry, new BorrowedFloat32Memory(volume));
		astra::CFloat32ProjectionData2D sinogram_data(
		    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));

		if (volume_data.getFloat32Memory() != volume) {
			g_last_error = "volume buffer was not borrowed zero-copy";
			return 0;
		}
		if (sinogram_data.getFloat32Memory() != sinogram) {
			g_last_error = "sinogram buffer was not borrowed zero-copy";
			return 0;
		}

		astra::CParallelBeamLineKernelProjector2D projector(
		    projection_geometry, volume_geometry);
		if (!projector.isInitialized()) {
			g_last_error = "failed to initialize parallel line projector";
			return 0;
		}

		BorrowedFilteredBackProjectionAlgorithm algorithm;
		const astra::SFilterConfig filter_config = build_filter_config(
		    filter_type,
		    custom_filter,
		    custom_filter_width,
		    custom_filter_height,
		    filter_d,
		    filter_parameter);
		if (!algorithm.initializeWithFilter(&projector, &volume_data, &sinogram_data, filter_config)) {
			g_last_error = "failed to initialize CPU FBP algorithm";
			return 0;
		}
		if (!algorithm.run()) {
			g_last_error = "CPU FBP run failed";
			return 0;
		}

		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
}

extern "C" int astra_julia_cuda_fbp2d_parallel_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_inputs(volume_width,
	                     volume_height,
	                     angle_count,
	                     detector_count,
	                     detector_width,
	                     angles,
	                     volume,
	                     const_cast<float*>(sinogram)) ||
	    !validate_filter_inputs(
	        filter_type, custom_filter, custom_filter_width, custom_filter_height, filter_d) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize projection geometry";
			return 0;
		}

		const astra::SFilterConfig filter_config = build_filter_config(
		    filter_type,
		    custom_filter,
		    custom_filter_width,
		    custom_filter_height,
		    filter_d,
		    filter_parameter);
		return run_cuda_fbp_2d(
		           volume_geometry, projection_geometry, sinogram, volume, filter_config, false, gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)angle_count;
	(void)detector_count;
	(void)detector_width;
	(void)angles;
	(void)sinogram;
	(void)volume;
	(void)filter_type;
	(void)custom_filter;
	(void)custom_filter_width;
	(void)custom_filter_height;
	(void)filter_d;
	(void)filter_parameter;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_fbp2d_parallel_vec_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_2d(volume_width,
	                            volume_height,
	                            angle_count,
	                            detector_count,
	                            vectors,
	                            sinogram,
	                            volume) ||
	    !validate_filter_inputs(
	        filter_type, custom_filter, custom_filter_width, custom_filter_height, filter_d) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		astra::CParallelVecProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    build_parallel_vec_geometry_2d(angle_count, detector_count, vectors));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize parallel vec projection geometry";
			return 0;
		}

		const astra::SFilterConfig filter_config = build_filter_config(
		    filter_type,
		    custom_filter,
		    custom_filter_width,
		    custom_filter_height,
		    filter_d,
		    filter_parameter);
		return run_cuda_fbp_2d(
		           volume_geometry, projection_geometry, sinogram, volume, filter_config, false, gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)angle_count;
	(void)detector_count;
	(void)vectors;
	(void)sinogram;
	(void)volume;
	(void)filter_type;
	(void)custom_filter;
	(void)custom_filter_width;
	(void)custom_filter_height;
	(void)filter_d;
	(void)filter_parameter;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_fbp2d_fanflat_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_inputs(volume_width,
	                     volume_height,
	                     angle_count,
	                     detector_count,
	                     detector_width,
	                     angles,
	                     volume,
	                     const_cast<float*>(sinogram)) ||
	    !validate_fanflat_distances(origin_source_distance, origin_detector_distance) ||
	    !validate_filter_inputs(
	        filter_type, custom_filter, custom_filter_width, custom_filter_height, filter_d) ||
	    !validate_short_scan_flag(short_scan) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CFanFlatProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    detector_width,
		    std::move(angle_vector),
		    origin_source_distance,
		    origin_detector_distance);

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize fanflat projection geometry";
			return 0;
		}

		const astra::SFilterConfig filter_config = build_filter_config(
		    filter_type,
		    custom_filter,
		    custom_filter_width,
		    custom_filter_height,
		    filter_d,
		    filter_parameter);
		return run_cuda_fbp_2d(
		           volume_geometry,
		           projection_geometry,
		           sinogram,
		           volume,
		           filter_config,
		           short_scan != 0,
		           gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)angle_count;
	(void)detector_count;
	(void)detector_width;
	(void)origin_source_distance;
	(void)origin_detector_distance;
	(void)angles;
	(void)sinogram;
	(void)volume;
	(void)filter_type;
	(void)custom_filter;
	(void)custom_filter_width;
	(void)custom_filter_height;
	(void)filter_d;
	(void)filter_parameter;
	(void)short_scan;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_fbp2d_fanflat_vec_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_2d(volume_width,
	                            volume_height,
	                            angle_count,
	                            detector_count,
	                            vectors,
	                            sinogram,
	                            volume) ||
	    !validate_filter_inputs(
	        filter_type, custom_filter, custom_filter_width, custom_filter_height, filter_d) ||
	    !validate_short_scan_flag(short_scan) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		astra::CFanFlatVecProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    build_fanflat_vec_geometry_2d(angle_count, detector_count, vectors));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize fanflat vec projection geometry";
			return 0;
		}

		const astra::SFilterConfig filter_config = build_filter_config(
		    filter_type,
		    custom_filter,
		    custom_filter_width,
		    custom_filter_height,
		    filter_d,
		    filter_parameter);
		return run_cuda_fbp_2d(
		           volume_geometry,
		           projection_geometry,
		           sinogram,
		           volume,
		           filter_config,
		           short_scan != 0,
		           gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)angle_count;
	(void)detector_count;
	(void)vectors;
	(void)sinogram;
	(void)volume;
	(void)filter_type;
	(void)custom_filter;
	(void)custom_filter_width;
	(void)custom_filter_height;
	(void)filter_d;
	(void)filter_parameter;
	(void)short_scan;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_sirt2d_parallel_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_inputs(volume_width,
	                     volume_height,
	                     angle_count,
	                     detector_count,
	                     detector_width,
	                     angles,
	                     volume,
	                     const_cast<float*>(sinogram)) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_pixel_supersampling(pixel_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize projection geometry";
			return 0;
		}

			return run_cuda_sirt_2d(
			           volume_geometry,
			           projection_geometry,
			           sinogram,
			           volume,
			           iterations,
			           relaxation,
			           reconstruction_mask,
			           sinogram_mask,
			           residual_norm,
			           use_min_constraint != 0,
			           min_constraint,
			           use_max_constraint != 0,
			           max_constraint,
			           detector_supersampling,
			           pixel_supersampling,
			           gpu_index)
			           ? 1
			           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)angle_count;
	(void)detector_count;
	(void)detector_width;
	(void)angles;
	(void)sinogram;
	(void)volume;
	(void)iterations;
	(void)relaxation;
		(void)reconstruction_mask;
		(void)sinogram_mask;
		(void)residual_norm;
		(void)use_min_constraint;
		(void)min_constraint;
		(void)use_max_constraint;
		(void)max_constraint;
		(void)detector_supersampling;
		(void)pixel_supersampling;
		(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_sart2d_parallel_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_inputs(volume_width,
	                     volume_height,
	                     angle_count,
	                     detector_count,
	                     detector_width,
	                     angles,
	                     volume,
	                     const_cast<float*>(sinogram)) ||
	    !validate_optional_volume_mask(
	        const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_projection_order_mode(projection_order_mode) ||
	    !validate_projection_order_list(
	        projection_order_mode, projection_order, projection_order_length, angle_count) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_pixel_supersampling(pixel_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize projection geometry";
			return 0;
		}

		return run_cuda_sart_2d(
		           volume_geometry,
		           projection_geometry,
		           sinogram,
		           volume,
		           iterations,
		           relaxation,
		           reconstruction_mask,
		           residual_norm,
		           use_min_constraint != 0,
		           min_constraint,
		           use_max_constraint != 0,
		           max_constraint,
		           projection_order_mode,
		           projection_order,
		           projection_order_length,
		           angle_count,
		           detector_supersampling,
		           pixel_supersampling,
		           gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width; (void)volume_height; (void)angle_count; (void)detector_count;
	(void)detector_width; (void)angles; (void)sinogram; (void)volume; (void)iterations;
	(void)relaxation; (void)reconstruction_mask; (void)residual_norm; (void)use_min_constraint;
	(void)min_constraint; (void)use_max_constraint; (void)max_constraint;
	(void)projection_order_mode; (void)projection_order; (void)projection_order_length;
	(void)detector_supersampling; (void)pixel_supersampling; (void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_sirt2d_parallel_vec_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_2d(volume_width,
	                            volume_height,
	                            angle_count,
		                            detector_count,
			                            vectors,
			                            sinogram,
			                            volume) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_pixel_supersampling(pixel_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		astra::CParallelVecProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    build_parallel_vec_geometry_2d(angle_count, detector_count, vectors));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize parallel vec projection geometry";
			return 0;
		}

				return run_cuda_sirt_2d(
				           volume_geometry,
				           projection_geometry,
				           sinogram,
				           volume,
				           iterations,
				           relaxation,
				           reconstruction_mask,
				           sinogram_mask,
				           residual_norm,
				           use_min_constraint != 0,
				           min_constraint,
				           use_max_constraint != 0,
				           max_constraint,
				           detector_supersampling,
				           pixel_supersampling,
				           gpu_index)
				           ? 1
				           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)angle_count;
	(void)detector_count;
	(void)vectors;
		(void)sinogram;
		(void)volume;
	(void)iterations;
	(void)relaxation;
		(void)reconstruction_mask;
		(void)sinogram_mask;
		(void)residual_norm;
		(void)use_min_constraint;
		(void)min_constraint;
		(void)use_max_constraint;
		(void)max_constraint;
		(void)detector_supersampling;
		(void)pixel_supersampling;
		(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_sart2d_parallel_vec_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_2d(volume_width,
	                            volume_height,
	                            angle_count,
	                            detector_count,
	                            vectors,
	                            sinogram,
	                            volume) ||
	    !validate_optional_volume_mask(
	        const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_projection_order_mode(projection_order_mode) ||
	    !validate_projection_order_list(
	        projection_order_mode, projection_order, projection_order_length, angle_count) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_pixel_supersampling(pixel_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		astra::CParallelVecProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    build_parallel_vec_geometry_2d(angle_count, detector_count, vectors));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize parallel vec projection geometry";
			return 0;
		}

		return run_cuda_sart_2d(
		           volume_geometry,
		           projection_geometry,
		           sinogram,
		           volume,
		           iterations,
		           relaxation,
		           reconstruction_mask,
		           residual_norm,
		           use_min_constraint != 0,
		           min_constraint,
		           use_max_constraint != 0,
		           max_constraint,
		           projection_order_mode,
		           projection_order,
		           projection_order_length,
		           angle_count,
		           detector_supersampling,
		           pixel_supersampling,
		           gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width; (void)volume_height; (void)angle_count; (void)detector_count;
	(void)vectors; (void)sinogram; (void)volume; (void)iterations; (void)relaxation;
	(void)reconstruction_mask; (void)residual_norm; (void)use_min_constraint; (void)min_constraint;
	(void)use_max_constraint; (void)max_constraint; (void)projection_order_mode;
	(void)projection_order; (void)projection_order_length;
	(void)detector_supersampling; (void)pixel_supersampling; (void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_sirt2d_fanflat_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_inputs(volume_width,
	                     volume_height,
	                     angle_count,
	                     detector_count,
		                     detector_width,
			                     angles,
			                     volume,
			                     const_cast<float*>(sinogram)) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_fanflat_distances(origin_source_distance, origin_detector_distance) ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_pixel_supersampling(pixel_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CFanFlatProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    detector_width,
		    std::move(angle_vector),
		    origin_source_distance,
		    origin_detector_distance);

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize fanflat projection geometry";
			return 0;
		}

			return run_cuda_sirt_2d(
			           volume_geometry,
			           projection_geometry,
			           sinogram,
			           volume,
			           iterations,
			           relaxation,
			           reconstruction_mask,
			           sinogram_mask,
			           residual_norm,
			           use_min_constraint != 0,
			           min_constraint,
			           use_max_constraint != 0,
			           max_constraint,
			           detector_supersampling,
			           pixel_supersampling,
			           gpu_index)
			           ? 1
			           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)angle_count;
	(void)detector_count;
	(void)detector_width;
	(void)origin_source_distance;
	(void)origin_detector_distance;
	(void)angles;
	(void)sinogram;
		(void)volume;
		(void)iterations;
		(void)relaxation;
		(void)reconstruction_mask;
		(void)sinogram_mask;
		(void)residual_norm;
		(void)use_min_constraint;
		(void)min_constraint;
		(void)use_max_constraint;
		(void)max_constraint;
		(void)detector_supersampling;
		(void)pixel_supersampling;
		(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_sart2d_fanflat_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_inputs(volume_width,
	                     volume_height,
	                     angle_count,
	                     detector_count,
	                     detector_width,
	                     angles,
	                     volume,
	                     const_cast<float*>(sinogram)) ||
	    !validate_fanflat_distances(origin_source_distance, origin_detector_distance) ||
	    !validate_optional_volume_mask(
	        const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_projection_order_mode(projection_order_mode) ||
	    !validate_projection_order_list(
	        projection_order_mode, projection_order, projection_order_length, angle_count) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_pixel_supersampling(pixel_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CFanFlatProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    detector_width,
		    std::move(angle_vector),
		    origin_source_distance,
		    origin_detector_distance);

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize fanflat projection geometry";
			return 0;
		}

		return run_cuda_sart_2d(
		           volume_geometry,
		           projection_geometry,
		           sinogram,
		           volume,
		           iterations,
		           relaxation,
		           reconstruction_mask,
		           residual_norm,
		           use_min_constraint != 0,
		           min_constraint,
		           use_max_constraint != 0,
		           max_constraint,
		           projection_order_mode,
		           projection_order,
		           projection_order_length,
		           angle_count,
		           detector_supersampling,
		           pixel_supersampling,
		           gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width; (void)volume_height; (void)angle_count; (void)detector_count;
	(void)detector_width; (void)origin_source_distance; (void)origin_detector_distance;
	(void)angles; (void)sinogram; (void)volume; (void)iterations; (void)relaxation;
	(void)reconstruction_mask; (void)residual_norm; (void)use_min_constraint; (void)min_constraint;
	(void)use_max_constraint; (void)max_constraint; (void)projection_order_mode;
	(void)projection_order; (void)projection_order_length;
	(void)detector_supersampling; (void)pixel_supersampling; (void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_sirt2d_fanflat_vec_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_2d(volume_width,
	                            volume_height,
	                            angle_count,
	                            detector_count,
			                            vectors,
			                            sinogram,
			                            volume) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_pixel_supersampling(pixel_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		astra::CFanFlatVecProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    build_fanflat_vec_geometry_2d(angle_count, detector_count, vectors));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize fanflat vec projection geometry";
			return 0;
		}

			return run_cuda_sirt_2d(
			           volume_geometry,
			           projection_geometry,
			           sinogram,
			           volume,
			           iterations,
			           relaxation,
			           reconstruction_mask,
			           sinogram_mask,
			           residual_norm,
			           use_min_constraint != 0,
			           min_constraint,
			           use_max_constraint != 0,
			           max_constraint,
			           detector_supersampling,
			           pixel_supersampling,
			           gpu_index)
			           ? 1
			           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)angle_count;
	(void)detector_count;
	(void)vectors;
		(void)sinogram;
		(void)volume;
		(void)iterations;
		(void)relaxation;
		(void)reconstruction_mask;
		(void)sinogram_mask;
		(void)residual_norm;
		(void)use_min_constraint;
		(void)min_constraint;
		(void)use_max_constraint;
		(void)max_constraint;
		(void)detector_supersampling;
		(void)pixel_supersampling;
		(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_sart2d_fanflat_vec_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_2d(volume_width,
	                            volume_height,
	                            angle_count,
	                            detector_count,
	                            vectors,
	                            sinogram,
	                            volume) ||
	    !validate_optional_volume_mask(
	        const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_projection_order_mode(projection_order_mode) ||
	    !validate_projection_order_list(
	        projection_order_mode, projection_order, projection_order_length, angle_count) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_pixel_supersampling(pixel_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		astra::CFanFlatVecProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    build_fanflat_vec_geometry_2d(angle_count, detector_count, vectors));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize fanflat vec projection geometry";
			return 0;
		}

		return run_cuda_sart_2d(
		           volume_geometry,
		           projection_geometry,
		           sinogram,
		           volume,
		           iterations,
		           relaxation,
		           reconstruction_mask,
		           residual_norm,
		           use_min_constraint != 0,
		           min_constraint,
		           use_max_constraint != 0,
		           max_constraint,
		           projection_order_mode,
		           projection_order,
		           projection_order_length,
		           angle_count,
		           detector_supersampling,
		           pixel_supersampling,
		           gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width; (void)volume_height; (void)angle_count; (void)detector_count;
	(void)vectors; (void)sinogram; (void)volume; (void)iterations; (void)relaxation;
	(void)reconstruction_mask; (void)residual_norm; (void)use_min_constraint; (void)min_constraint;
	(void)use_max_constraint; (void)max_constraint; (void)projection_order_mode;
	(void)projection_order; (void)projection_order_length;
	(void)detector_supersampling; (void)pixel_supersampling; (void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_cgls2d_parallel_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_inputs(volume_width,
	                     volume_height,
	                     angle_count,
	                     detector_count,
	                     detector_width,
	                     angles,
	                     volume,
	                     const_cast<float*>(sinogram)) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_iterations(iterations) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_pixel_supersampling(pixel_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize projection geometry";
			return 0;
		}

		return run_cuda_cgls_2d(
		           volume_geometry,
		           projection_geometry,
		           sinogram,
		           volume,
		           iterations,
		           reconstruction_mask,
		           residual_norm,
		           detector_supersampling,
		           pixel_supersampling,
		           gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)angle_count;
	(void)detector_count;
	(void)detector_width;
	(void)angles;
	(void)sinogram;
	(void)volume;
	(void)iterations;
	(void)reconstruction_mask;
	(void)residual_norm;
	(void)detector_supersampling;
	(void)pixel_supersampling;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_em2d_parallel_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_inputs(volume_width,
	                     volume_height,
	                     angle_count,
	                     detector_count,
	                     detector_width,
	                     angles,
	                     volume,
	                     const_cast<float*>(sinogram)) ||
	    !validate_iterations(iterations) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_pixel_supersampling(pixel_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize projection geometry";
			return 0;
		}

		return run_cuda_em_2d(volume_geometry,
		                      projection_geometry,
		                      sinogram,
		                      volume,
		                      iterations,
		                      residual_norm,
		                      detector_supersampling,
		                      pixel_supersampling,
		                      gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)angle_count;
	(void)detector_count;
	(void)detector_width;
	(void)angles;
	(void)sinogram;
	(void)volume;
	(void)iterations;
	(void)residual_norm;
	(void)detector_supersampling;
	(void)pixel_supersampling;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_cgls2d_parallel_vec_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_2d(volume_width,
	                            volume_height,
	                            angle_count,
	                            detector_count,
		                            vectors,
		                            sinogram,
		                            volume) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_iterations(iterations) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_pixel_supersampling(pixel_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		astra::CParallelVecProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    build_parallel_vec_geometry_2d(angle_count, detector_count, vectors));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize parallel vec projection geometry";
			return 0;
		}

			return run_cuda_cgls_2d(
			           volume_geometry,
			           projection_geometry,
			           sinogram,
			           volume,
			           iterations,
			           reconstruction_mask,
			           residual_norm,
			           detector_supersampling,
			           pixel_supersampling,
			           gpu_index)
			           ? 1
			           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)angle_count;
	(void)detector_count;
	(void)vectors;
		(void)sinogram;
		(void)volume;
		(void)iterations;
		(void)reconstruction_mask;
		(void)residual_norm;
		(void)detector_supersampling;
		(void)pixel_supersampling;
		(void)gpu_index;
		g_last_error = "ASTRA was built without CUDA support";
		return 0;
	#endif
}

extern "C" int astra_julia_cuda_cgls2d_fanflat_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_inputs(volume_width,
	                     volume_height,
	                     angle_count,
	                     detector_count,
	                     detector_width,
		                     angles,
		                     volume,
		                     const_cast<float*>(sinogram)) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_fanflat_distances(origin_source_distance, origin_detector_distance) ||
	    !validate_iterations(iterations) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_pixel_supersampling(pixel_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CFanFlatProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    detector_width,
		    std::move(angle_vector),
		    origin_source_distance,
		    origin_detector_distance);

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize fanflat projection geometry";
			return 0;
		}

			return run_cuda_cgls_2d(
			           volume_geometry,
			           projection_geometry,
			           sinogram,
			           volume,
			           iterations,
			           reconstruction_mask,
			           residual_norm,
			           detector_supersampling,
			           pixel_supersampling,
			           gpu_index)
			           ? 1
			           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)angle_count;
	(void)detector_count;
	(void)detector_width;
	(void)origin_source_distance;
	(void)origin_detector_distance;
	(void)angles;
		(void)sinogram;
		(void)volume;
	(void)iterations;
	(void)reconstruction_mask;
	(void)residual_norm;
	(void)detector_supersampling;
	(void)pixel_supersampling;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
	#endif
}

extern "C" int astra_julia_cuda_cgls2d_fanflat_vec_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_2d(volume_width,
	                            volume_height,
	                            angle_count,
	                            detector_count,
		                            vectors,
		                            sinogram,
		                            volume) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_iterations(iterations) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_pixel_supersampling(pixel_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		astra::CFanFlatVecProjectionGeometry2D projection_geometry(
		    angle_count,
		    detector_count,
		    build_fanflat_vec_geometry_2d(angle_count, detector_count, vectors));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize fanflat vec projection geometry";
			return 0;
		}

			return run_cuda_cgls_2d(
			           volume_geometry,
			           projection_geometry,
			           sinogram,
			           volume,
			           iterations,
			           reconstruction_mask,
			           residual_norm,
			           detector_supersampling,
			           pixel_supersampling,
			           gpu_index)
			           ? 1
			           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)angle_count;
	(void)detector_count;
	(void)vectors;
		(void)sinogram;
		(void)volume;
		(void)iterations;
		(void)reconstruction_mask;
		(void)residual_norm;
		(void)detector_supersampling;
		(void)pixel_supersampling;
		(void)gpu_index;
		g_last_error = "ASTRA was built without CUDA support";
		return 0;
	#endif
}

extern "C" int astra_julia_cuda_fp3d_parallel_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_inputs_3d(volume_width,
	                        volume_height,
	                        volume_depth,
	                        angle_count,
	                        detector_count_u,
	                        detector_count_v,
	                        detector_spacing_u,
	                        detector_spacing_v,
	                        angles,
	                        volume,
	                        sinogram)) {
		return 0;
	}

	if (gpu_index < -1) {
		g_last_error = "gpu_index must be >= -1";
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry3D volume_geometry; init_volume_geometry_3d(volume_geometry, volume_width, volume_height, volume_depth);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry3D projection_geometry(
		    angle_count,
		    detector_count_v,
		    detector_count_u,
		    detector_spacing_u,
		    detector_spacing_v,
		    std::move(angle_vector));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D projection geometry";
			return 0;
		}

		astra::CFloat32VolumeData3D volume_data(
		    volume_geometry, new BorrowedFloat32Memory(const_cast<float*>(volume)));
		astra::CFloat32ProjectionData3D sinogram_data(
		    projection_geometry, new BorrowedFloat32Memory(sinogram));

		if (volume_data.getFloat32Memory() != volume) {
			g_last_error = "3D volume buffer was not borrowed zero-copy";
			return 0;
		}
		if (sinogram_data.getFloat32Memory() != sinogram) {
			g_last_error = "3D sinogram buffer was not borrowed zero-copy";
			return 0;
		}

		astra::CCompositeGeometryManager cgm;
		if (gpu_index >= 0) {
			cgm.setGPUIndices(std::vector<int>{gpu_index});
		}
		if (!cgm.doFP(nullptr, &volume_data, &sinogram_data, astra::CCompositeGeometryManager::MODE_SET)) {
			g_last_error = "3D CUDA forward projection run failed";
			return 0;
		}
		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)volume_depth;
	(void)angle_count;
	(void)detector_count_u;
	(void)detector_count_v;
	(void)detector_spacing_u;
	(void)detector_spacing_v;
	(void)angles;
	(void)volume;
	(void)sinogram;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_bp3d_parallel_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_inputs_3d(volume_width,
	                        volume_height,
	                        volume_depth,
	                        angle_count,
	                        detector_count_u,
	                        detector_count_v,
	                        detector_spacing_u,
	                        detector_spacing_v,
	                        angles,
	                        volume,
	                        const_cast<float*>(sinogram)) ||
	    !validate_voxel_supersampling(voxel_supersampling)) {
		return 0;
	}

	if (gpu_index < -1) {
		g_last_error = "gpu_index must be >= -1";
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry3D volume_geometry; init_volume_geometry_3d(volume_geometry, volume_width, volume_height, volume_depth);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry3D projection_geometry(
		    angle_count,
		    detector_count_v,
		    detector_count_u,
		    detector_spacing_u,
		    detector_spacing_v,
		    std::move(angle_vector));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D projection geometry";
			return 0;
		}

		const bool ok = astra::astraCudaBP(
		    volume,
		    sinogram,
		    &volume_geometry,
		    &projection_geometry,
		    gpu_index,
		    voxel_supersampling);
		if (!ok) {
			g_last_error = "3D parallel astraCudaBP failed";
			return 0;
		}
		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)volume_depth;
	(void)angle_count;
	(void)detector_count_u;
	(void)detector_count_v;
	(void)detector_spacing_u;
	(void)detector_spacing_v;
	(void)angles;
	(void)sinogram;
	(void)volume;
	(void)voxel_supersampling;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_fp3d_parallel_vec_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    const float* vectors,
    const float* volume,
    float* sinogram,
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_3d(volume_width,
	                            volume_height,
	                            volume_depth,
	                            angle_count,
	                            detector_count_u,
	                            detector_count_v,
	                            vectors,
	                            volume,
	                            sinogram)) {
		return 0;
	}

	if (gpu_index < -1) {
		g_last_error = "gpu_index must be >= -1";
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry3D volume_geometry; init_volume_geometry_3d(volume_geometry, volume_width, volume_height, volume_depth);
		astra::CParallelVecProjectionGeometry3D projection_geometry(
		    angle_count,
		    detector_count_v,
		    detector_count_u,
		    build_parallel_vec_geometry(angle_count, detector_count_u, detector_count_v, vectors));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D parallel vec geometry";
			return 0;
		}

		const bool ok = astra::astraCudaFP(
		    volume,
		    sinogram,
		    &volume_geometry,
		    &projection_geometry,
		    gpu_index,
		    1,
		    astra::ker3d_default);
		if (!ok) {
			g_last_error = "3D parallel vec astraCudaFP failed";
			return 0;
		}
		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)volume_depth;
	(void)angle_count;
	(void)detector_count_u;
	(void)detector_count_v;
	(void)vectors;
	(void)volume;
	(void)sinogram;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_bp3d_parallel_vec_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_3d(volume_width,
	                            volume_height,
	                            volume_depth,
	                            angle_count,
	                            detector_count_u,
	                            detector_count_v,
	                            vectors,
	                            sinogram,
	                            volume) ||
	    !validate_voxel_supersampling(voxel_supersampling)) {
		return 0;
	}

	if (gpu_index < -1) {
		g_last_error = "gpu_index must be >= -1";
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry3D volume_geometry; init_volume_geometry_3d(volume_geometry, volume_width, volume_height, volume_depth);
		astra::CParallelVecProjectionGeometry3D projection_geometry(
		    angle_count,
		    detector_count_v,
		    detector_count_u,
		    build_parallel_vec_geometry(angle_count, detector_count_u, detector_count_v, vectors));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D parallel vec geometry";
			return 0;
		}

		const bool ok = astra::astraCudaBP(
		    volume,
		    sinogram,
		    &volume_geometry,
		    &projection_geometry,
		    gpu_index,
		    voxel_supersampling);
		if (!ok) {
			g_last_error = "3D parallel vec astraCudaBP failed";
			return 0;
		}
		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)volume_depth;
	(void)angle_count;
	(void)detector_count_u;
	(void)detector_count_v;
	(void)vectors;
	(void)sinogram;
	(void)volume;
	(void)voxel_supersampling;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_fp3d_cone_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_inputs_3d(volume_width,
	                        volume_height,
	                        volume_depth,
	                        angle_count,
	                        detector_count_u,
	                        detector_count_v,
	                        detector_spacing_u,
	                        detector_spacing_v,
	                        angles,
	                        volume,
	                        sinogram) ||
	    !validate_cone_distances(origin_source_distance, origin_detector_distance) ||
	    !validate_detector_supersampling(detector_supersampling)) {
		return 0;
	}

	if (gpu_index < -1) {
		g_last_error = "gpu_index must be >= -1";
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry3D volume_geometry; init_volume_geometry_3d(volume_geometry, volume_width, volume_height, volume_depth);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CConeProjectionGeometry3D projection_geometry(
		    angle_count,
		    detector_count_v,
		    detector_count_u,
		    detector_spacing_u,
		    detector_spacing_v,
		    std::move(angle_vector),
		    origin_source_distance,
		    origin_detector_distance);

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D cone projection geometry";
			return 0;
		}

		const bool ok = astra::astraCudaFP(
		    volume,
		    sinogram,
		    &volume_geometry,
		    &projection_geometry,
		    gpu_index,
		    detector_supersampling,
		    astra::ker3d_default);
		if (!ok) {
			g_last_error = "3D cone astraCudaFP failed";
			return 0;
		}
		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)volume_depth;
	(void)angle_count;
	(void)detector_count_u;
	(void)detector_count_v;
	(void)detector_spacing_u;
	(void)detector_spacing_v;
	(void)origin_source_distance;
	(void)origin_detector_distance;
	(void)angles;
	(void)volume;
	(void)sinogram;
	(void)detector_supersampling;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_bp3d_cone_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_inputs_3d(volume_width,
	                        volume_height,
	                        volume_depth,
	                        angle_count,
	                        detector_count_u,
	                        detector_count_v,
	                        detector_spacing_u,
	                        detector_spacing_v,
	                        angles,
	                        volume,
	                        const_cast<float*>(sinogram)) ||
	    !validate_cone_distances(origin_source_distance, origin_detector_distance) ||
	    !validate_voxel_supersampling(voxel_supersampling)) {
		return 0;
	}

	if (gpu_index < -1) {
		g_last_error = "gpu_index must be >= -1";
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry3D volume_geometry; init_volume_geometry_3d(volume_geometry, volume_width, volume_height, volume_depth);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CConeProjectionGeometry3D projection_geometry(
		    angle_count,
		    detector_count_v,
		    detector_count_u,
		    detector_spacing_u,
		    detector_spacing_v,
		    std::move(angle_vector),
		    origin_source_distance,
		    origin_detector_distance);

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D cone projection geometry";
			return 0;
		}

		const bool ok = astra::astraCudaBP(
		    volume,
		    sinogram,
		    &volume_geometry,
		    &projection_geometry,
		    gpu_index,
		    voxel_supersampling);
		if (!ok) {
			g_last_error = "3D cone astraCudaBP failed";
			return 0;
		}
		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)volume_depth;
	(void)angle_count;
	(void)detector_count_u;
	(void)detector_count_v;
	(void)detector_spacing_u;
	(void)detector_spacing_v;
	(void)origin_source_distance;
	(void)origin_detector_distance;
	(void)angles;
	(void)sinogram;
	(void)volume;
	(void)voxel_supersampling;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_fp3d_cone_vec_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_3d(volume_width,
	                            volume_height,
	                            volume_depth,
	                            angle_count,
	                            detector_count_u,
	                            detector_count_v,
	                            vectors,
	                            volume,
	                            sinogram) ||
	    !validate_detector_supersampling(detector_supersampling)) {
		return 0;
	}

	if (gpu_index < -1) {
		g_last_error = "gpu_index must be >= -1";
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry3D volume_geometry; init_volume_geometry_3d(volume_geometry, volume_width, volume_height, volume_depth);
		astra::CConeVecProjectionGeometry3D projection_geometry(
		    angle_count,
		    detector_count_v,
		    detector_count_u,
		    build_cone_vec_geometry(angle_count, detector_count_u, detector_count_v, vectors));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D cone vec geometry";
			return 0;
		}

		const bool ok = astra::astraCudaFP(
		    volume,
		    sinogram,
		    &volume_geometry,
		    &projection_geometry,
		    gpu_index,
		    detector_supersampling,
		    astra::ker3d_default);
		if (!ok) {
			g_last_error = "3D cone vec astraCudaFP failed";
			return 0;
		}
		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)volume_depth;
	(void)angle_count;
	(void)detector_count_u;
	(void)detector_count_v;
	(void)vectors;
	(void)volume;
	(void)sinogram;
	(void)detector_supersampling;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_bp3d_cone_vec_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_3d(volume_width,
	                            volume_height,
	                            volume_depth,
	                            angle_count,
	                            detector_count_u,
	                            detector_count_v,
	                            vectors,
	                            sinogram,
	                            volume) ||
	    !validate_voxel_supersampling(voxel_supersampling)) {
		return 0;
	}

	if (gpu_index < -1) {
		g_last_error = "gpu_index must be >= -1";
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry3D volume_geometry; init_volume_geometry_3d(volume_geometry, volume_width, volume_height, volume_depth);
		astra::CConeVecProjectionGeometry3D projection_geometry(
		    angle_count,
		    detector_count_v,
		    detector_count_u,
		    build_cone_vec_geometry(angle_count, detector_count_u, detector_count_v, vectors));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D cone vec geometry";
			return 0;
		}

		const bool ok = astra::astraCudaBP(
		    volume,
		    sinogram,
		    &volume_geometry,
		    &projection_geometry,
		    gpu_index,
		    voxel_supersampling);
		if (!ok) {
			g_last_error = "3D cone vec astraCudaBP failed";
			return 0;
		}
		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width;
	(void)volume_height;
	(void)volume_depth;
	(void)angle_count;
	(void)detector_count_u;
	(void)detector_count_v;
	(void)vectors;
	(void)sinogram;
	(void)volume;
	(void)voxel_supersampling;
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_fp3d_cyl_cone_vec_f32(
    int volume_width,
    int volume_height,
    int volume_depth,
    int angle_count,
    int detector_count_u,
    int detector_count_v,
    const float* vectors,
    const float* volume,
    float* sinogram,
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_3d(volume_width,
	                            volume_height,
	                            volume_depth,
	                            angle_count,
	                            detector_count_u,
	                            detector_count_v,
	                            vectors,
	                            volume,
	                            sinogram) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry3D volume_geometry; init_volume_geometry_3d(volume_geometry, volume_width, volume_height, volume_depth);
		astra::CCylConeVecProjectionGeometry3D projection_geometry(
		    angle_count,
		    detector_count_v,
		    detector_count_u,
		    build_cyl_cone_vec_geometry(angle_count, vectors));
		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D cyl_cone_vec geometry";
			return 0;
		}
		return run_cuda_fp_3d_cgm(volume_geometry, projection_geometry, volume, sinogram, gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width; (void)volume_height; (void)volume_depth;
	(void)angle_count; (void)detector_count_u; (void)detector_count_v;
	(void)vectors; (void)volume; (void)sinogram; (void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_bp3d_cyl_cone_vec_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_3d(volume_width,
	                            volume_height,
	                            volume_depth,
	                            angle_count,
	                            detector_count_u,
	                            detector_count_v,
	                            vectors,
	                            sinogram,
	                            volume) ||
	    !validate_voxel_supersampling(voxel_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		if (voxel_supersampling != 1) {
			g_last_error =
			    "3D cyl_cone_vec BP supports voxel_supersampling == 1 only in the current ASTRA CUDA backend";
			return 0;
		}
		astra::CVolumeGeometry3D volume_geometry; init_volume_geometry_3d(volume_geometry, volume_width, volume_height, volume_depth);
		astra::CCylConeVecProjectionGeometry3D projection_geometry(
		    angle_count,
		    detector_count_v,
		    detector_count_u,
		    build_cyl_cone_vec_geometry(angle_count, vectors));
		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D cyl_cone_vec geometry";
			return 0;
		}

		BorrowedCudaProjector3D projector;
		if (!projector.initializeWithOptions(
		        projection_geometry,
		        volume_geometry,
		        astra::ker3d_default,
		        voxel_supersampling,
		        1,
		        gpu_index)) {
			g_last_error = "failed to initialize 3D cyl_cone_vec CUDA projector";
			return 0;
		}

		astra::CFloat32VolumeData3D volume_data(
		    volume_geometry, new BorrowedFloat32Memory(volume));
		astra::CFloat32ProjectionData3D sinogram_data(
		    projection_geometry, new BorrowedFloat32Memory(const_cast<float*>(sinogram)));
		if (volume_data.getFloat32Memory() != volume) {
			g_last_error = "3D volume buffer was not borrowed zero-copy";
			return 0;
		}
		if (sinogram_data.getFloat32Memory() != sinogram) {
			g_last_error = "3D sinogram buffer was not borrowed zero-copy";
			return 0;
		}

		astra::CCompositeGeometryManager cgm;
		if (gpu_index >= 0) {
			cgm.setGPUIndices(std::vector<int>{gpu_index});
		}
		if (!cgm.doBP(&projector, &volume_data, &sinogram_data, astra::CCompositeGeometryManager::MODE_SET)) {
			g_last_error = "3D cyl_cone_vec backprojection run failed";
			return 0;
		}
		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width; (void)volume_height; (void)volume_depth;
	(void)angle_count; (void)detector_count_u; (void)detector_count_v;
	(void)vectors; (void)sinogram; (void)volume; (void)voxel_supersampling; (void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_sirt3d_parallel_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_inputs_3d(volume_width,
	                        volume_height,
	                        volume_depth,
	                        angle_count,
	                        detector_count_u,
	                        detector_count_v,
	                        detector_spacing_u,
	                        detector_spacing_v,
	                        angles,
	                        volume,
	                        const_cast<float*>(sinogram)) ||
	    !validate_optional_volume_mask_3d(
	        const_cast<float*>(reconstruction_mask), volume_width, volume_height, volume_depth) ||
	    !validate_optional_sinogram_mask_3d(
	        const_cast<float*>(sinogram_mask), detector_count_u, angle_count, detector_count_v) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_voxel_supersampling(voxel_supersampling) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry3D volume_geometry; init_volume_geometry_3d(volume_geometry, volume_width, volume_height, volume_depth);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry3D projection_geometry(
		    angle_count,
		    detector_count_v,
		    detector_count_u,
		    detector_spacing_u,
		    detector_spacing_v,
		    std::move(angle_vector));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D parallel projection geometry";
			return 0;
		}

		return run_cuda_sirt_3d(
		           volume_geometry,
		           projection_geometry,
		           sinogram,
		           volume,
		           iterations,
		           relaxation,
		           reconstruction_mask,
		           sinogram_mask,
		           residual_norm,
		           use_min_constraint != 0,
		           min_constraint,
		           use_max_constraint != 0,
		           max_constraint,
		           voxel_supersampling,
		           detector_supersampling,
		           gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width; (void)volume_height; (void)volume_depth;
	(void)angle_count; (void)detector_count_u; (void)detector_count_v;
	(void)detector_spacing_u; (void)detector_spacing_v; (void)angles;
	(void)sinogram; (void)volume; (void)iterations; (void)relaxation;
	(void)reconstruction_mask; (void)sinogram_mask; (void)residual_norm;
	(void)use_min_constraint; (void)min_constraint; (void)use_max_constraint; (void)max_constraint;
	(void)voxel_supersampling; (void)detector_supersampling; (void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_sirt3d_parallel_vec_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_3d(volume_width,
	                            volume_height,
	                            volume_depth,
	                            angle_count,
	                            detector_count_u,
	                            detector_count_v,
	                            vectors,
	                            sinogram,
	                            volume) ||
	    !validate_optional_volume_mask_3d(
	        const_cast<float*>(reconstruction_mask), volume_width, volume_height, volume_depth) ||
	    !validate_optional_sinogram_mask_3d(
	        const_cast<float*>(sinogram_mask), detector_count_u, angle_count, detector_count_v) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_voxel_supersampling(voxel_supersampling) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry3D volume_geometry; init_volume_geometry_3d(volume_geometry, volume_width, volume_height, volume_depth);
		astra::CParallelVecProjectionGeometry3D projection_geometry(
		    angle_count,
		    detector_count_v,
		    detector_count_u,
		    build_parallel_vec_geometry(angle_count, detector_count_u, detector_count_v, vectors));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D parallel vec geometry";
			return 0;
		}

		return run_cuda_sirt_3d(
		           volume_geometry,
		           projection_geometry,
		           sinogram,
		           volume,
		           iterations,
		           relaxation,
		           reconstruction_mask,
		           sinogram_mask,
		           residual_norm,
		           use_min_constraint != 0,
		           min_constraint,
		           use_max_constraint != 0,
		           max_constraint,
		           voxel_supersampling,
		           detector_supersampling,
		           gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width; (void)volume_height; (void)volume_depth;
	(void)angle_count; (void)detector_count_u; (void)detector_count_v;
	(void)vectors; (void)sinogram; (void)volume; (void)iterations; (void)relaxation;
	(void)reconstruction_mask; (void)sinogram_mask; (void)residual_norm;
	(void)use_min_constraint; (void)min_constraint; (void)use_max_constraint; (void)max_constraint;
	(void)voxel_supersampling; (void)detector_supersampling; (void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_sirt3d_cone_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_inputs_3d(volume_width,
	                        volume_height,
	                        volume_depth,
	                        angle_count,
	                        detector_count_u,
	                        detector_count_v,
	                        detector_spacing_u,
	                        detector_spacing_v,
	                        angles,
	                        volume,
	                        const_cast<float*>(sinogram)) ||
	    !validate_optional_volume_mask_3d(
	        const_cast<float*>(reconstruction_mask), volume_width, volume_height, volume_depth) ||
	    !validate_optional_sinogram_mask_3d(
	        const_cast<float*>(sinogram_mask), detector_count_u, angle_count, detector_count_v) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_cone_distances(origin_source_distance, origin_detector_distance) ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_voxel_supersampling(voxel_supersampling) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry3D volume_geometry; init_volume_geometry_3d(volume_geometry, volume_width, volume_height, volume_depth);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CConeProjectionGeometry3D projection_geometry(
		    angle_count,
		    detector_count_v,
		    detector_count_u,
		    detector_spacing_u,
		    detector_spacing_v,
		    std::move(angle_vector),
		    origin_source_distance,
		    origin_detector_distance);

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D cone projection geometry";
			return 0;
		}

		return run_cuda_sirt_3d(
		           volume_geometry,
		           projection_geometry,
		           sinogram,
		           volume,
		           iterations,
		           relaxation,
		           reconstruction_mask,
		           sinogram_mask,
		           residual_norm,
		           use_min_constraint != 0,
		           min_constraint,
		           use_max_constraint != 0,
		           max_constraint,
		           voxel_supersampling,
		           detector_supersampling,
		           gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width; (void)volume_height; (void)volume_depth;
	(void)angle_count; (void)detector_count_u; (void)detector_count_v;
	(void)detector_spacing_u; (void)detector_spacing_v;
	(void)origin_source_distance; (void)origin_detector_distance;
	(void)angles; (void)sinogram; (void)volume; (void)iterations; (void)relaxation;
	(void)reconstruction_mask; (void)sinogram_mask; (void)residual_norm;
	(void)use_min_constraint; (void)min_constraint; (void)use_max_constraint; (void)max_constraint;
	(void)voxel_supersampling; (void)detector_supersampling; (void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_sirt3d_cone_vec_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_3d(volume_width,
	                            volume_height,
	                            volume_depth,
	                            angle_count,
	                            detector_count_u,
	                            detector_count_v,
	                            vectors,
	                            sinogram,
	                            volume) ||
	    !validate_optional_volume_mask_3d(
	        const_cast<float*>(reconstruction_mask), volume_width, volume_height, volume_depth) ||
	    !validate_optional_sinogram_mask_3d(
	        const_cast<float*>(sinogram_mask), detector_count_u, angle_count, detector_count_v) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_voxel_supersampling(voxel_supersampling) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry3D volume_geometry; init_volume_geometry_3d(volume_geometry, volume_width, volume_height, volume_depth);
		astra::CConeVecProjectionGeometry3D projection_geometry(
		    angle_count,
		    detector_count_v,
		    detector_count_u,
		    build_cone_vec_geometry(angle_count, detector_count_u, detector_count_v, vectors));

		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D cone vec geometry";
			return 0;
		}

		return run_cuda_sirt_3d(
		           volume_geometry,
		           projection_geometry,
		           sinogram,
		           volume,
		           iterations,
		           relaxation,
		           reconstruction_mask,
		           sinogram_mask,
		           residual_norm,
		           use_min_constraint != 0,
		           min_constraint,
		           use_max_constraint != 0,
		           max_constraint,
		           voxel_supersampling,
		           detector_supersampling,
		           gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width; (void)volume_height; (void)volume_depth;
	(void)angle_count; (void)detector_count_u; (void)detector_count_v;
	(void)vectors; (void)sinogram; (void)volume; (void)iterations; (void)relaxation;
	(void)reconstruction_mask; (void)sinogram_mask; (void)residual_norm;
	(void)use_min_constraint; (void)min_constraint; (void)use_max_constraint; (void)max_constraint;
	(void)voxel_supersampling; (void)detector_supersampling; (void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_sirt3d_cyl_cone_vec_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_3d(volume_width,
	                            volume_height,
	                            volume_depth,
	                            angle_count,
	                            detector_count_u,
	                            detector_count_v,
	                            vectors,
	                            sinogram,
	                            volume) ||
	    !validate_optional_volume_mask_3d(
	        const_cast<float*>(reconstruction_mask), volume_width, volume_height, volume_depth) ||
	    !validate_optional_sinogram_mask_3d(
	        const_cast<float*>(sinogram_mask), detector_count_u, angle_count, detector_count_v) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_voxel_supersampling(voxel_supersampling) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry3D volume_geometry; init_volume_geometry_3d(volume_geometry, volume_width, volume_height, volume_depth);
		astra::CCylConeVecProjectionGeometry3D projection_geometry(
		    angle_count,
		    detector_count_v,
		    detector_count_u,
		    build_cyl_cone_vec_geometry(angle_count, vectors));
		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D cyl_cone_vec geometry";
			return 0;
		}
		return run_cuda_sirt_3d(
		           volume_geometry,
		           projection_geometry,
		           sinogram,
		           volume,
		           iterations,
		           relaxation,
		           reconstruction_mask,
		           sinogram_mask,
		           residual_norm,
		           use_min_constraint != 0,
		           min_constraint,
		           use_max_constraint != 0,
		           max_constraint,
		           voxel_supersampling,
		           detector_supersampling,
		           gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width; (void)volume_height; (void)volume_depth;
	(void)angle_count; (void)detector_count_u; (void)detector_count_v;
	(void)vectors; (void)sinogram; (void)volume; (void)iterations; (void)relaxation;
	(void)reconstruction_mask; (void)sinogram_mask; (void)residual_norm;
	(void)use_min_constraint; (void)min_constraint; (void)use_max_constraint; (void)max_constraint;
	(void)voxel_supersampling; (void)detector_supersampling; (void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_cgls3d_parallel_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_inputs_3d(volume_width,
	                        volume_height,
	                        volume_depth,
	                        angle_count,
	                        detector_count_u,
	                        detector_count_v,
	                        detector_spacing_u,
	                        detector_spacing_v,
	                        angles,
	                        volume,
	                        const_cast<float*>(sinogram)) ||
	    !validate_optional_volume_mask_3d(
	        const_cast<float*>(reconstruction_mask), volume_width, volume_height, volume_depth) ||
	    !validate_iterations(iterations) ||
	    !validate_voxel_supersampling(voxel_supersampling) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry3D volume_geometry; init_volume_geometry_3d(volume_geometry, volume_width, volume_height, volume_depth);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry3D projection_geometry(
		    angle_count,
		    detector_count_v,
		    detector_count_u,
		    detector_spacing_u,
		    detector_spacing_v,
		    std::move(angle_vector));
		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D parallel projection geometry";
			return 0;
		}
		return run_cuda_cgls_3d(
		           volume_geometry,
		           projection_geometry,
		           sinogram,
		           volume,
		           iterations,
		           reconstruction_mask,
		           residual_norm,
		           voxel_supersampling,
		           detector_supersampling,
		           gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width; (void)volume_height; (void)volume_depth;
	(void)angle_count; (void)detector_count_u; (void)detector_count_v;
	(void)detector_spacing_u; (void)detector_spacing_v; (void)angles;
	(void)sinogram; (void)volume; (void)iterations; (void)reconstruction_mask; (void)residual_norm;
	(void)voxel_supersampling; (void)detector_supersampling; (void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_cgls3d_parallel_vec_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_3d(volume_width,
	                            volume_height,
	                            volume_depth,
	                            angle_count,
	                            detector_count_u,
	                            detector_count_v,
	                            vectors,
	                            sinogram,
	                            volume) ||
	    !validate_optional_volume_mask_3d(
	        const_cast<float*>(reconstruction_mask), volume_width, volume_height, volume_depth) ||
	    !validate_iterations(iterations) ||
	    !validate_voxel_supersampling(voxel_supersampling) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry3D volume_geometry; init_volume_geometry_3d(volume_geometry, volume_width, volume_height, volume_depth);
		astra::CParallelVecProjectionGeometry3D projection_geometry(
		    angle_count,
		    detector_count_v,
		    detector_count_u,
		    build_parallel_vec_geometry(angle_count, detector_count_u, detector_count_v, vectors));
		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D parallel vec geometry";
			return 0;
		}
		return run_cuda_cgls_3d(
		           volume_geometry,
		           projection_geometry,
		           sinogram,
		           volume,
		           iterations,
		           reconstruction_mask,
		           residual_norm,
		           voxel_supersampling,
		           detector_supersampling,
		           gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width; (void)volume_height; (void)volume_depth;
	(void)angle_count; (void)detector_count_u; (void)detector_count_v;
	(void)vectors; (void)sinogram; (void)volume; (void)iterations; (void)reconstruction_mask; (void)residual_norm;
	(void)voxel_supersampling; (void)detector_supersampling; (void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_cgls3d_cone_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_inputs_3d(volume_width,
	                        volume_height,
	                        volume_depth,
	                        angle_count,
	                        detector_count_u,
	                        detector_count_v,
	                        detector_spacing_u,
	                        detector_spacing_v,
	                        angles,
	                        volume,
	                        const_cast<float*>(sinogram)) ||
	    !validate_optional_volume_mask_3d(
	        const_cast<float*>(reconstruction_mask), volume_width, volume_height, volume_depth) ||
	    !validate_cone_distances(origin_source_distance, origin_detector_distance) ||
	    !validate_iterations(iterations) ||
	    !validate_voxel_supersampling(voxel_supersampling) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry3D volume_geometry; init_volume_geometry_3d(volume_geometry, volume_width, volume_height, volume_depth);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CConeProjectionGeometry3D projection_geometry(
		    angle_count,
		    detector_count_v,
		    detector_count_u,
		    detector_spacing_u,
		    detector_spacing_v,
		    std::move(angle_vector),
		    origin_source_distance,
		    origin_detector_distance);
		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D cone projection geometry";
			return 0;
		}
		return run_cuda_cgls_3d(
		           volume_geometry,
		           projection_geometry,
		           sinogram,
		           volume,
		           iterations,
		           reconstruction_mask,
		           residual_norm,
		           voxel_supersampling,
		           detector_supersampling,
		           gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width; (void)volume_height; (void)volume_depth;
	(void)angle_count; (void)detector_count_u; (void)detector_count_v;
	(void)detector_spacing_u; (void)detector_spacing_v;
	(void)origin_source_distance; (void)origin_detector_distance;
	(void)angles; (void)sinogram; (void)volume; (void)iterations; (void)reconstruction_mask; (void)residual_norm;
	(void)voxel_supersampling; (void)detector_supersampling; (void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_cgls3d_cone_vec_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_3d(volume_width,
	                            volume_height,
	                            volume_depth,
	                            angle_count,
	                            detector_count_u,
	                            detector_count_v,
	                            vectors,
	                            sinogram,
	                            volume) ||
	    !validate_optional_volume_mask_3d(
	        const_cast<float*>(reconstruction_mask), volume_width, volume_height, volume_depth) ||
	    !validate_iterations(iterations) ||
	    !validate_voxel_supersampling(voxel_supersampling) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry3D volume_geometry; init_volume_geometry_3d(volume_geometry, volume_width, volume_height, volume_depth);
		astra::CConeVecProjectionGeometry3D projection_geometry(
		    angle_count,
		    detector_count_v,
		    detector_count_u,
		    build_cone_vec_geometry(angle_count, detector_count_u, detector_count_v, vectors));
		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D cone vec geometry";
			return 0;
		}
		return run_cuda_cgls_3d(
		           volume_geometry,
		           projection_geometry,
		           sinogram,
		           volume,
		           iterations,
		           reconstruction_mask,
		           residual_norm,
		           voxel_supersampling,
		           detector_supersampling,
		           gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width; (void)volume_height; (void)volume_depth;
	(void)angle_count; (void)detector_count_u; (void)detector_count_v;
	(void)vectors; (void)sinogram; (void)volume; (void)iterations; (void)reconstruction_mask; (void)residual_norm;
	(void)voxel_supersampling; (void)detector_supersampling; (void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_cgls3d_cyl_cone_vec_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_3d(volume_width,
	                            volume_height,
	                            volume_depth,
	                            angle_count,
	                            detector_count_u,
	                            detector_count_v,
	                            vectors,
	                            sinogram,
	                            volume) ||
	    !validate_optional_volume_mask_3d(
	        const_cast<float*>(reconstruction_mask), volume_width, volume_height, volume_depth) ||
	    !validate_iterations(iterations) ||
	    !validate_voxel_supersampling(voxel_supersampling) ||
	    !validate_detector_supersampling(detector_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry3D volume_geometry; init_volume_geometry_3d(volume_geometry, volume_width, volume_height, volume_depth);
		astra::CCylConeVecProjectionGeometry3D projection_geometry(
		    angle_count,
		    detector_count_v,
		    detector_count_u,
		    build_cyl_cone_vec_geometry(angle_count, vectors));
		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D cyl_cone_vec geometry";
			return 0;
		}
		return run_cuda_cgls_3d(
		           volume_geometry,
		           projection_geometry,
		           sinogram,
		           volume,
		           iterations,
		           reconstruction_mask,
		           residual_norm,
		           voxel_supersampling,
		           detector_supersampling,
		           gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width; (void)volume_height; (void)volume_depth;
	(void)angle_count; (void)detector_count_u; (void)detector_count_v;
	(void)vectors; (void)sinogram; (void)volume; (void)iterations; (void)reconstruction_mask;
	(void)residual_norm; (void)voxel_supersampling; (void)detector_supersampling; (void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_fdk3d_cone_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_inputs_3d(volume_width,
	                        volume_height,
	                        volume_depth,
	                        angle_count,
	                        detector_count_u,
	                        detector_count_v,
	                        detector_spacing_u,
	                        detector_spacing_v,
	                        angles,
	                        volume,
	                        const_cast<float*>(sinogram)) ||
	    !validate_cone_distances(origin_source_distance, origin_detector_distance) ||
	    !validate_filter_inputs(
	        filter_type, custom_filter, custom_filter_width, custom_filter_height, filter_d) ||
	    !validate_short_scan_flag(short_scan) ||
	    !validate_voxel_supersampling(voxel_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry3D volume_geometry; init_volume_geometry_3d(volume_geometry, volume_width, volume_height, volume_depth);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CConeProjectionGeometry3D projection_geometry(
		    angle_count,
		    detector_count_v,
		    detector_count_u,
		    detector_spacing_u,
		    detector_spacing_v,
		    std::move(angle_vector),
		    origin_source_distance,
		    origin_detector_distance);
		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D cone projection geometry";
			return 0;
		}

		const astra::SFilterConfig filter_config = build_filter_config(
		    filter_type,
		    custom_filter,
		    custom_filter_width,
		    custom_filter_height,
		    filter_d,
		    filter_parameter);
		return run_cuda_fdk_3d(
		           volume_geometry,
		           projection_geometry,
		           sinogram,
		           volume,
		           filter_config,
		           short_scan != 0,
		           voxel_supersampling,
		           gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width; (void)volume_height; (void)volume_depth;
	(void)angle_count; (void)detector_count_u; (void)detector_count_v;
	(void)detector_spacing_u; (void)detector_spacing_v;
	(void)origin_source_distance; (void)origin_detector_distance;
	(void)angles; (void)sinogram; (void)volume;
	(void)filter_type; (void)custom_filter; (void)custom_filter_width; (void)custom_filter_height;
	(void)filter_d; (void)filter_parameter; (void)short_scan; (void)voxel_supersampling; (void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_cuda_fdk3d_cone_vec_f32(
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
    int gpu_index)
{
	g_last_error.clear();

	if (!validate_vec_inputs_3d(volume_width,
	                            volume_height,
	                            volume_depth,
	                            angle_count,
	                            detector_count_u,
	                            detector_count_v,
	                            vectors,
	                            sinogram,
	                            volume) ||
	    !validate_filter_inputs(
	        filter_type, custom_filter, custom_filter_width, custom_filter_height, filter_d) ||
	    !validate_short_scan_flag(short_scan) ||
	    !validate_voxel_supersampling(voxel_supersampling) ||
	    !validate_gpu_index(gpu_index)) {
		return 0;
	}

#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	try {
		astra::CVolumeGeometry3D volume_geometry; init_volume_geometry_3d(volume_geometry, volume_width, volume_height, volume_depth);
		astra::CConeVecProjectionGeometry3D projection_geometry(
		    angle_count,
		    detector_count_v,
		    detector_count_u,
		    build_cone_vec_geometry(angle_count, detector_count_u, detector_count_v, vectors));
		if (!volume_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D volume geometry";
			return 0;
		}
		if (!projection_geometry.isInitialized()) {
			g_last_error = "failed to initialize 3D cone vec geometry";
			return 0;
		}

		const astra::SFilterConfig filter_config = build_filter_config(
		    filter_type,
		    custom_filter,
		    custom_filter_width,
		    custom_filter_height,
		    filter_d,
		    filter_parameter);
		return run_cuda_fdk_3d(
		           volume_geometry,
		           projection_geometry,
		           sinogram,
		           volume,
		           filter_config,
		           short_scan != 0,
		           voxel_supersampling,
		           gpu_index)
		           ? 1
		           : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception";
		return 0;
	}
#else
	(void)volume_width; (void)volume_height; (void)volume_depth;
	(void)angle_count; (void)detector_count_u; (void)detector_count_v;
	(void)vectors; (void)sinogram; (void)volume;
	(void)filter_type; (void)custom_filter; (void)custom_filter_width; (void)custom_filter_height;
	(void)filter_d; (void)filter_parameter; (void)short_scan; (void)voxel_supersampling; (void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}


#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
static std::string g_gpu_info_buffer;
#endif

extern "C" int astra_julia_has_cuda(void)
{
	return astra::hasFeature("cuda") ? 1 : 0;
}

extern "C" int astra_julia_has_feature(const char* feature)
{
	if (!feature) return 0;
	return astra::hasFeature(feature) ? 1 : 0;
}

extern "C" int astra_julia_get_gpu_count(void)
{
#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	int count = 0;
	cudaError_t err = cudaGetDeviceCount(&count);
	if (err != cudaSuccess) {
		g_last_error = cudaGetErrorString(err);
		return 0;
	}
	return count;
#else
	return 0;
#endif
}

extern "C" const char* astra_julia_get_gpu_info(int gpu_index)
{
#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	g_gpu_info_buffer = astraCUDA::getCudaDeviceString(gpu_index);
	return g_gpu_info_buffer.c_str();
#else
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return "";
#endif
}

extern "C" int astra_julia_set_gpu_index(int gpu_index)
{
#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	if (!astraCUDA::setGPUIndex(gpu_index)) {
		g_last_error = "Failed to set GPU index";
		return 0;
	}
	return 1;
#else
	(void)gpu_index;
	g_last_error = "ASTRA was built without CUDA support";
	return 0;
#endif
}

extern "C" int astra_julia_get_gpu_index(void)
{
#ifdef ASTRA_CUDA
#include <cuda_runtime.h>
	int dev = -1;
	cudaError_t err = cudaGetDevice(&dev);
	if (err != cudaSuccess) {
		g_last_error = cudaGetErrorString(err);
		return -1;
	}
	return dev;
#else
	return -1;
#endif
}

// Parallel linear
extern "C" int astra_julia_fp2d_parallel_linear_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count, float detector_width,
    const float* angles, const float* volume, float* sinogram)
{
	g_last_error.clear();
	if (!validate_inputs(volume_width, volume_height, angle_count, detector_count, detector_width, angles, const_cast<float*>(volume), sinogram)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, 1, "parallel", angle_count, detector_count, nullptr);
		if (!proj) return 0;
		return run_cpu_fp_2d(volume_geometry, projection_geometry, proj.get(), volume, sinogram) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_bp2d_parallel_linear_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count, float detector_width,
    const float* angles, const float* sinogram, float* volume)
{
	g_last_error.clear();
	if (!validate_inputs(volume_width, volume_height, angle_count, detector_count, detector_width, angles, volume, const_cast<float*>(sinogram))) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, 1, "parallel", angle_count, detector_count, nullptr);
		if (!proj) return 0;
		return run_cpu_bp_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

// Parallel vec linear
extern "C" int astra_julia_fp2d_parallel_vec_linear_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count,
    const float* vectors, const float* volume, float* sinogram)
{
	g_last_error.clear();
	if (!validate_vec_inputs_2d(volume_width, volume_height, angle_count, detector_count, vectors, const_cast<float*>(volume), sinogram)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		auto projection_vectors = build_parallel_vec_geometry_2d(angle_count, detector_count, vectors);
		astra::CParallelVecProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, std::move(projection_vectors));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, 1, "parallel_vec", angle_count, detector_count, vectors);
		if (!proj) return 0;
		return run_cpu_fp_2d(volume_geometry, projection_geometry, proj.get(), volume, sinogram) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_bp2d_parallel_vec_linear_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count,
    const float* vectors, const float* sinogram, float* volume)
{
	g_last_error.clear();
	if (!validate_vec_inputs_2d(volume_width, volume_height, angle_count, detector_count, vectors, volume, const_cast<float*>(sinogram))) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		auto projection_vectors = build_parallel_vec_geometry_2d(angle_count, detector_count, vectors);
		astra::CParallelVecProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, std::move(projection_vectors));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, 1, "parallel_vec", angle_count, detector_count, vectors);
		if (!proj) return 0;
		return run_cpu_bp_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

// Parallel strip
extern "C" int astra_julia_fp2d_parallel_strip_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count, float detector_width,
    const float* angles, const float* volume, float* sinogram)
{
	g_last_error.clear();
	if (!validate_inputs(volume_width, volume_height, angle_count, detector_count, detector_width, angles, const_cast<float*>(volume), sinogram)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, 2, "parallel", angle_count, detector_count, nullptr);
		if (!proj) return 0;
		return run_cpu_fp_2d(volume_geometry, projection_geometry, proj.get(), volume, sinogram) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_bp2d_parallel_strip_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count, float detector_width,
    const float* angles, const float* sinogram, float* volume)
{
	g_last_error.clear();
	if (!validate_inputs(volume_width, volume_height, angle_count, detector_count, detector_width, angles, volume, const_cast<float*>(sinogram))) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, 2, "parallel", angle_count, detector_count, nullptr);
		if (!proj) return 0;
		return run_cpu_bp_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

// Parallel vec strip
extern "C" int astra_julia_fp2d_parallel_vec_strip_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count,
    const float* vectors, const float* volume, float* sinogram)
{
	g_last_error.clear();
	if (!validate_vec_inputs_2d(volume_width, volume_height, angle_count, detector_count, vectors, const_cast<float*>(volume), sinogram)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		auto projection_vectors = build_parallel_vec_geometry_2d(angle_count, detector_count, vectors);
		astra::CParallelVecProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, std::move(projection_vectors));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, 2, "parallel_vec", angle_count, detector_count, vectors);
		if (!proj) return 0;
		return run_cpu_fp_2d(volume_geometry, projection_geometry, proj.get(), volume, sinogram) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_bp2d_parallel_vec_strip_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count,
    const float* vectors, const float* sinogram, float* volume)
{
	g_last_error.clear();
	if (!validate_vec_inputs_2d(volume_width, volume_height, angle_count, detector_count, vectors, volume, const_cast<float*>(sinogram))) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		auto projection_vectors = build_parallel_vec_geometry_2d(angle_count, detector_count, vectors);
		astra::CParallelVecProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, std::move(projection_vectors));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, 2, "parallel_vec", angle_count, detector_count, vectors);
		if (!proj) return 0;
		return run_cpu_bp_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

// FanFlat strip
extern "C" int astra_julia_fp2d_fanflat_strip_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count, float detector_width,
    float origin_source_distance, float origin_detector_distance,
    const float* angles, const float* volume, float* sinogram)
{
	g_last_error.clear();
	if (!validate_inputs(volume_width, volume_height, angle_count, detector_count, detector_width, angles, const_cast<float*>(volume), sinogram) ||
	    !validate_fanflat_distances(origin_source_distance, origin_detector_distance)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CFanFlatProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector),
		    origin_source_distance, origin_detector_distance);
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, 2, "fanflat", angle_count, detector_count, nullptr);
		if (!proj) return 0;
		return run_cpu_fp_2d(volume_geometry, projection_geometry, proj.get(), volume, sinogram) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_bp2d_fanflat_strip_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count, float detector_width,
    float origin_source_distance, float origin_detector_distance,
    const float* angles, const float* sinogram, float* volume)
{
	g_last_error.clear();
	if (!validate_inputs(volume_width, volume_height, angle_count, detector_count, detector_width, angles, volume, const_cast<float*>(sinogram)) ||
	    !validate_fanflat_distances(origin_source_distance, origin_detector_distance)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CFanFlatProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector),
		    origin_source_distance, origin_detector_distance);
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, 2, "fanflat", angle_count, detector_count, nullptr);
		if (!proj) return 0;
		return run_cpu_bp_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

// Parallel distance-driven
extern "C" int astra_julia_fp2d_parallel_distance_driven_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count, float detector_width,
    const float* angles, const float* volume, float* sinogram)
{
	g_last_error.clear();
	if (!validate_inputs(volume_width, volume_height, angle_count, detector_count, detector_width, angles, const_cast<float*>(volume), sinogram)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, 3, "parallel", angle_count, detector_count, nullptr);
		if (!proj) return 0;
		return run_cpu_fp_2d(volume_geometry, projection_geometry, proj.get(), volume, sinogram) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_bp2d_parallel_distance_driven_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count, float detector_width,
    const float* angles, const float* sinogram, float* volume)
{
	g_last_error.clear();
	if (!validate_inputs(volume_width, volume_height, angle_count, detector_count, detector_width, angles, volume, const_cast<float*>(sinogram))) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, 3, "parallel", angle_count, detector_count, nullptr);
		if (!proj) return 0;
		return run_cpu_bp_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

// Parallel vec distance-driven
extern "C" int astra_julia_fp2d_parallel_vec_distance_driven_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count,
    const float* vectors, const float* volume, float* sinogram)
{
	g_last_error.clear();
	if (!validate_vec_inputs_2d(volume_width, volume_height, angle_count, detector_count, vectors, const_cast<float*>(volume), sinogram)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		auto projection_vectors = build_parallel_vec_geometry_2d(angle_count, detector_count, vectors);
		astra::CParallelVecProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, std::move(projection_vectors));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, 3, "parallel_vec", angle_count, detector_count, vectors);
		if (!proj) return 0;
		return run_cpu_fp_2d(volume_geometry, projection_geometry, proj.get(), volume, sinogram) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_bp2d_parallel_vec_distance_driven_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count,
    const float* vectors, const float* sinogram, float* volume)
{
	g_last_error.clear();
	if (!validate_vec_inputs_2d(volume_width, volume_height, angle_count, detector_count, vectors, volume, const_cast<float*>(sinogram))) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		auto projection_vectors = build_parallel_vec_geometry_2d(angle_count, detector_count, vectors);
		astra::CParallelVecProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, std::move(projection_vectors));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, 3, "parallel_vec", angle_count, detector_count, vectors);
		if (!proj) return 0;
		return run_cpu_bp_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

// CPU SIRT
extern "C" int astra_julia_sirt2d_parallel_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count, float detector_width,
    const float* angles, const float* sinogram, float* volume,
    int iterations, float relaxation, int projector_kernel,
    const float* reconstruction_mask, const float* sinogram_mask,
    int use_min_constraint, float min_constraint,
    int use_max_constraint, float max_constraint)
{
	g_last_error.clear();
	if (!validate_inputs(volume_width, volume_height, angle_count, detector_count, detector_width, angles, volume, const_cast<float*>(sinogram)) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_projector_kernel(projector_kernel)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, projector_kernel, "parallel", angle_count, detector_count, nullptr);
		if (!proj) return 0;
		return run_cpu_sirt_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume, iterations, relaxation, reconstruction_mask, sinogram_mask, use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_sirt2d_parallel_vec_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count,
    const float* vectors, const float* sinogram, float* volume,
    int iterations, float relaxation, int projector_kernel,
    const float* reconstruction_mask, const float* sinogram_mask,
    int use_min_constraint, float min_constraint,
    int use_max_constraint, float max_constraint)
{
	g_last_error.clear();
	if (!validate_vec_inputs_2d(volume_width, volume_height, angle_count, detector_count, vectors, volume, const_cast<float*>(sinogram)) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_projector_kernel(projector_kernel)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		auto projection_vectors = build_parallel_vec_geometry_2d(angle_count, detector_count, vectors);
		astra::CParallelVecProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, std::move(projection_vectors));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, projector_kernel, "parallel_vec", angle_count, detector_count, vectors);
		if (!proj) return 0;
		return run_cpu_sirt_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume, iterations, relaxation, reconstruction_mask, sinogram_mask, use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_sirt2d_fanflat_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count, float detector_width,
    float origin_source_distance, float origin_detector_distance,
    const float* angles, const float* sinogram, float* volume,
    int iterations, float relaxation, int projector_kernel,
    const float* reconstruction_mask, const float* sinogram_mask,
    int use_min_constraint, float min_constraint,
    int use_max_constraint, float max_constraint)
{
	g_last_error.clear();
	if (!validate_inputs(volume_width, volume_height, angle_count, detector_count, detector_width, angles, volume, const_cast<float*>(sinogram)) ||
	    !validate_fanflat_distances(origin_source_distance, origin_detector_distance) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_projector_kernel(projector_kernel)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CFanFlatProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector),
		    origin_source_distance, origin_detector_distance);
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, projector_kernel, "fanflat", angle_count, detector_count, nullptr);
		if (!proj) return 0;
		return run_cpu_sirt_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume, iterations, relaxation, reconstruction_mask, sinogram_mask, use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_sirt2d_fanflat_vec_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count,
    const float* vectors, const float* sinogram, float* volume,
    int iterations, float relaxation, int projector_kernel,
    const float* reconstruction_mask, const float* sinogram_mask,
    int use_min_constraint, float min_constraint,
    int use_max_constraint, float max_constraint)
{
	g_last_error.clear();
	if (!validate_vec_inputs_2d(volume_width, volume_height, angle_count, detector_count, vectors, volume, const_cast<float*>(sinogram)) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_projector_kernel(projector_kernel)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		auto projection_vectors = build_fanflat_vec_geometry_2d(angle_count, detector_count, vectors);
		astra::CFanFlatVecProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, std::move(projection_vectors));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, projector_kernel, "fanflat_vec", angle_count, detector_count, vectors);
		if (!proj) return 0;
		return run_cpu_sirt_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume, iterations, relaxation, reconstruction_mask, sinogram_mask, use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

// CPU SART
extern "C" int astra_julia_sart2d_parallel_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count, float detector_width,
    const float* angles, const float* sinogram, float* volume,
    int iterations, float relaxation,
    int projection_order_mode, const int* projection_order, int projection_order_length,
    int projector_kernel,
    const float* reconstruction_mask, const float* sinogram_mask,
    int use_min_constraint, float min_constraint,
    int use_max_constraint, float max_constraint)
{
	g_last_error.clear();
	if (!validate_inputs(volume_width, volume_height, angle_count, detector_count, detector_width, angles, volume, const_cast<float*>(sinogram)) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_projection_order_mode(projection_order_mode) ||
	    !validate_projection_order_list(projection_order_mode, projection_order, projection_order_length, angle_count) ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_projector_kernel(projector_kernel)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, projector_kernel, "parallel", angle_count, detector_count, nullptr);
		if (!proj) return 0;
		return run_cpu_sart_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume, iterations, relaxation, projection_order_mode, projection_order, projection_order_length, angle_count, reconstruction_mask, sinogram_mask, use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_sart2d_parallel_vec_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count,
    const float* vectors, const float* sinogram, float* volume,
    int iterations, float relaxation,
    int projection_order_mode, const int* projection_order, int projection_order_length,
    int projector_kernel,
    const float* reconstruction_mask, const float* sinogram_mask,
    int use_min_constraint, float min_constraint,
    int use_max_constraint, float max_constraint)
{
	g_last_error.clear();
	if (!validate_vec_inputs_2d(volume_width, volume_height, angle_count, detector_count, vectors, volume, const_cast<float*>(sinogram)) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_projection_order_mode(projection_order_mode) ||
	    !validate_projection_order_list(projection_order_mode, projection_order, projection_order_length, angle_count) ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_projector_kernel(projector_kernel)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		auto projection_vectors = build_parallel_vec_geometry_2d(angle_count, detector_count, vectors);
		astra::CParallelVecProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, std::move(projection_vectors));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, projector_kernel, "parallel_vec", angle_count, detector_count, vectors);
		if (!proj) return 0;
		return run_cpu_sart_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume, iterations, relaxation, projection_order_mode, projection_order, projection_order_length, angle_count, reconstruction_mask, sinogram_mask, use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_sart2d_fanflat_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count, float detector_width,
    float origin_source_distance, float origin_detector_distance,
    const float* angles, const float* sinogram, float* volume,
    int iterations, float relaxation,
    int projection_order_mode, const int* projection_order, int projection_order_length,
    int projector_kernel,
    const float* reconstruction_mask, const float* sinogram_mask,
    int use_min_constraint, float min_constraint,
    int use_max_constraint, float max_constraint)
{
	g_last_error.clear();
	if (!validate_inputs(volume_width, volume_height, angle_count, detector_count, detector_width, angles, volume, const_cast<float*>(sinogram)) ||
	    !validate_fanflat_distances(origin_source_distance, origin_detector_distance) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_projection_order_mode(projection_order_mode) ||
	    !validate_projection_order_list(projection_order_mode, projection_order, projection_order_length, angle_count) ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_projector_kernel(projector_kernel)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CFanFlatProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector),
		    origin_source_distance, origin_detector_distance);
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, projector_kernel, "fanflat", angle_count, detector_count, nullptr);
		if (!proj) return 0;
		return run_cpu_sart_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume, iterations, relaxation, projection_order_mode, projection_order, projection_order_length, angle_count, reconstruction_mask, sinogram_mask, use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_sart2d_fanflat_vec_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count,
    const float* vectors, const float* sinogram, float* volume,
    int iterations, float relaxation,
    int projection_order_mode, const int* projection_order, int projection_order_length,
    int projector_kernel,
    const float* reconstruction_mask, const float* sinogram_mask,
    int use_min_constraint, float min_constraint,
    int use_max_constraint, float max_constraint)
{
	g_last_error.clear();
	if (!validate_vec_inputs_2d(volume_width, volume_height, angle_count, detector_count, vectors, volume, const_cast<float*>(sinogram)) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_projection_order_mode(projection_order_mode) ||
	    !validate_projection_order_list(projection_order_mode, projection_order, projection_order_length, angle_count) ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_projector_kernel(projector_kernel)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		auto projection_vectors = build_fanflat_vec_geometry_2d(angle_count, detector_count, vectors);
		astra::CFanFlatVecProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, std::move(projection_vectors));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, projector_kernel, "fanflat_vec", angle_count, detector_count, vectors);
		if (!proj) return 0;
		return run_cpu_sart_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume, iterations, relaxation, projection_order_mode, projection_order, projection_order_length, angle_count, reconstruction_mask, sinogram_mask, use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

// CPU CGLS
extern "C" int astra_julia_cgls2d_parallel_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count, float detector_width,
    const float* angles, const float* sinogram, float* volume,
    int iterations, int projector_kernel,
    const float* reconstruction_mask, const float* sinogram_mask,
    int use_min_constraint, float min_constraint,
    int use_max_constraint, float max_constraint)
{
	g_last_error.clear();
	if (!validate_inputs(volume_width, volume_height, angle_count, detector_count, detector_width, angles, volume, const_cast<float*>(sinogram)) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_projector_kernel(projector_kernel)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, projector_kernel, "parallel", angle_count, detector_count, nullptr);
		if (!proj) return 0;
		return run_cpu_cgls_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume, iterations, reconstruction_mask, sinogram_mask, use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_cgls2d_parallel_vec_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count,
    const float* vectors, const float* sinogram, float* volume,
    int iterations, int projector_kernel,
    const float* reconstruction_mask, const float* sinogram_mask,
    int use_min_constraint, float min_constraint,
    int use_max_constraint, float max_constraint)
{
	g_last_error.clear();
	if (!validate_vec_inputs_2d(volume_width, volume_height, angle_count, detector_count, vectors, volume, const_cast<float*>(sinogram)) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_projector_kernel(projector_kernel)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		auto projection_vectors = build_parallel_vec_geometry_2d(angle_count, detector_count, vectors);
		astra::CParallelVecProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, std::move(projection_vectors));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, projector_kernel, "parallel_vec", angle_count, detector_count, vectors);
		if (!proj) return 0;
		return run_cpu_cgls_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume, iterations, reconstruction_mask, sinogram_mask, use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_cgls2d_fanflat_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count, float detector_width,
    float origin_source_distance, float origin_detector_distance,
    const float* angles, const float* sinogram, float* volume,
    int iterations, int projector_kernel,
    const float* reconstruction_mask, const float* sinogram_mask,
    int use_min_constraint, float min_constraint,
    int use_max_constraint, float max_constraint)
{
	g_last_error.clear();
	if (!validate_inputs(volume_width, volume_height, angle_count, detector_count, detector_width, angles, volume, const_cast<float*>(sinogram)) ||
	    !validate_fanflat_distances(origin_source_distance, origin_detector_distance) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_projector_kernel(projector_kernel)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CFanFlatProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector),
		    origin_source_distance, origin_detector_distance);
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, projector_kernel, "fanflat", angle_count, detector_count, nullptr);
		if (!proj) return 0;
		return run_cpu_cgls_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume, iterations, reconstruction_mask, sinogram_mask, use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_cgls2d_fanflat_vec_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count,
    const float* vectors, const float* sinogram, float* volume,
    int iterations, int projector_kernel,
    const float* reconstruction_mask, const float* sinogram_mask,
    int use_min_constraint, float min_constraint,
    int use_max_constraint, float max_constraint)
{
	g_last_error.clear();
	if (!validate_vec_inputs_2d(volume_width, volume_height, angle_count, detector_count, vectors, volume, const_cast<float*>(sinogram)) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_projector_kernel(projector_kernel)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		auto projection_vectors = build_fanflat_vec_geometry_2d(angle_count, detector_count, vectors);
		astra::CFanFlatVecProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, std::move(projection_vectors));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, projector_kernel, "fanflat_vec", angle_count, detector_count, vectors);
		if (!proj) return 0;
		return run_cpu_cgls_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume, iterations, reconstruction_mask, sinogram_mask, use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

// CPU ART
extern "C" int astra_julia_art2d_parallel_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count, float detector_width,
    const float* angles, const float* sinogram, float* volume,
    int iterations, float relaxation, int projector_kernel,
    const float* reconstruction_mask, const float* sinogram_mask,
    int use_min_constraint, float min_constraint,
    int use_max_constraint, float max_constraint)
{
	g_last_error.clear();
	if (!validate_inputs(volume_width, volume_height, angle_count, detector_count, detector_width, angles, volume, const_cast<float*>(sinogram)) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_projector_kernel(projector_kernel)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CParallelProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, projector_kernel, "parallel", angle_count, detector_count, nullptr);
		if (!proj) return 0;
		return run_cpu_art_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume, iterations, relaxation, reconstruction_mask, sinogram_mask, use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_art2d_parallel_vec_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count,
    const float* vectors, const float* sinogram, float* volume,
    int iterations, float relaxation, int projector_kernel,
    const float* reconstruction_mask, const float* sinogram_mask,
    int use_min_constraint, float min_constraint,
    int use_max_constraint, float max_constraint)
{
	g_last_error.clear();
	if (!validate_vec_inputs_2d(volume_width, volume_height, angle_count, detector_count, vectors, volume, const_cast<float*>(sinogram)) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_projector_kernel(projector_kernel)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		auto projection_vectors = build_parallel_vec_geometry_2d(angle_count, detector_count, vectors);
		astra::CParallelVecProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, std::move(projection_vectors));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, projector_kernel, "parallel_vec", angle_count, detector_count, vectors);
		if (!proj) return 0;
		return run_cpu_art_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume, iterations, relaxation, reconstruction_mask, sinogram_mask, use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_art2d_fanflat_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count, float detector_width,
    float origin_source_distance, float origin_detector_distance,
    const float* angles, const float* sinogram, float* volume,
    int iterations, float relaxation, int projector_kernel,
    const float* reconstruction_mask, const float* sinogram_mask,
    int use_min_constraint, float min_constraint,
    int use_max_constraint, float max_constraint)
{
	g_last_error.clear();
	if (!validate_inputs(volume_width, volume_height, angle_count, detector_count, detector_width, angles, volume, const_cast<float*>(sinogram)) ||
	    !validate_fanflat_distances(origin_source_distance, origin_detector_distance) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_projector_kernel(projector_kernel)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		std::vector<astra::float32> angle_vector(angles, angles + angle_count);
		astra::CFanFlatProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, detector_width, std::move(angle_vector),
		    origin_source_distance, origin_detector_distance);
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, projector_kernel, "fanflat", angle_count, detector_count, nullptr);
		if (!proj) return 0;
		return run_cpu_art_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume, iterations, relaxation, reconstruction_mask, sinogram_mask, use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_art2d_fanflat_vec_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count,
    const float* vectors, const float* sinogram, float* volume,
    int iterations, float relaxation, int projector_kernel,
    const float* reconstruction_mask, const float* sinogram_mask,
    int use_min_constraint, float min_constraint,
    int use_max_constraint, float max_constraint)
{
	g_last_error.clear();
	if (!validate_vec_inputs_2d(volume_width, volume_height, angle_count, detector_count, vectors, volume, const_cast<float*>(sinogram)) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_projector_kernel(projector_kernel)) {
		return 0;
	}
	try {
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		auto projection_vectors = build_fanflat_vec_geometry_2d(angle_count, detector_count, vectors);
		astra::CFanFlatVecProjectionGeometry2D projection_geometry(
		    angle_count, detector_count, std::move(projection_vectors));
		if (!volume_geometry.isInitialized() || !projection_geometry.isInitialized()) return 0;
		auto proj = create_cpu_projector_2d(volume_geometry, projection_geometry, projector_kernel, "fanflat_vec", angle_count, detector_count, vectors);
		if (!proj) return 0;
		return run_cpu_art_2d(volume_geometry, projection_geometry, proj.get(), sinogram, volume, iterations, relaxation, reconstruction_mask, sinogram_mask, use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

// ---------------- Sparse Matrix 2D ----------------

extern "C" int astra_julia_fp2d_sparse_matrix_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count,
    uint64_t nnz,
    const uint64_t* row_starts,
    const uint32_t* col_indices,
    const float* values,
    const float* volume,
    float* sinogram)
{
	g_last_error.clear();
	if (!validate_sparse_matrix_inputs(volume_width, volume_height, angle_count, detector_count, nnz, row_starts, col_indices, values, volume, sinogram)) {
		return 0;
	}
	try {
		BorrowedSparseMatrix sparse_matrix(
		    static_cast<unsigned int>(angle_count * detector_count),
		    static_cast<unsigned int>(volume_width * volume_height),
		    static_cast<unsigned long>(nnz),
		    values, col_indices, row_starts);
		astra::CSparseMatrixProjectionGeometry2D projection_geometry(angle_count, detector_count, &sparse_matrix);
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		if (!projection_geometry.isInitialized() || !volume_geometry.isInitialized()) return 0;
		astra::CSparseMatrixProjector2D proj(projection_geometry, volume_geometry);
		if (!proj.isInitialized()) {
			g_last_error = "failed to initialize sparse matrix projector";
			return 0;
		}
		return run_cpu_fp_2d(volume_geometry, projection_geometry, &proj, volume, sinogram) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_bp2d_sparse_matrix_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count,
    uint64_t nnz,
    const uint64_t* row_starts,
    const uint32_t* col_indices,
    const float* values,
    const float* sinogram,
    float* volume)
{
	g_last_error.clear();
	if (!validate_sparse_matrix_inputs(volume_width, volume_height, angle_count, detector_count, nnz, row_starts, col_indices, values, sinogram, volume)) {
		return 0;
	}
	try {
		BorrowedSparseMatrix sparse_matrix(
		    static_cast<unsigned int>(angle_count * detector_count),
		    static_cast<unsigned int>(volume_width * volume_height),
		    static_cast<unsigned long>(nnz),
		    values, col_indices, row_starts);
		astra::CSparseMatrixProjectionGeometry2D projection_geometry(angle_count, detector_count, &sparse_matrix);
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		if (!projection_geometry.isInitialized() || !volume_geometry.isInitialized()) return 0;
		astra::CSparseMatrixProjector2D proj(projection_geometry, volume_geometry);
		if (!proj.isInitialized()) {
			g_last_error = "failed to initialize sparse matrix projector";
			return 0;
		}
		return run_cpu_bp_2d(volume_geometry, projection_geometry, &proj, sinogram, volume) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_sirt2d_sparse_matrix_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count,
    uint64_t nnz,
    const uint64_t* row_starts,
    const uint32_t* col_indices,
    const float* values,
    const float* sinogram,
    float* volume,
    int iterations, float relaxation,
    const float* reconstruction_mask, const float* sinogram_mask,
    int use_min_constraint, float min_constraint,
    int use_max_constraint, float max_constraint)
{
	g_last_error.clear();
	if (!validate_sparse_matrix_inputs(volume_width, volume_height, angle_count, detector_count, nnz, row_starts, col_indices, values, sinogram, volume) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation)) {
		return 0;
	}
	try {
		BorrowedSparseMatrix sparse_matrix(
		    static_cast<unsigned int>(angle_count * detector_count),
		    static_cast<unsigned int>(volume_width * volume_height),
		    static_cast<unsigned long>(nnz),
		    values, col_indices, row_starts);
		astra::CSparseMatrixProjectionGeometry2D projection_geometry(angle_count, detector_count, &sparse_matrix);
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		if (!projection_geometry.isInitialized() || !volume_geometry.isInitialized()) return 0;
		astra::CSparseMatrixProjector2D proj(projection_geometry, volume_geometry);
		if (!proj.isInitialized()) {
			g_last_error = "failed to initialize sparse matrix projector";
			return 0;
		}
		return run_cpu_sirt_2d(volume_geometry, projection_geometry, &proj, sinogram, volume, iterations, relaxation, reconstruction_mask, sinogram_mask, use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_sart2d_sparse_matrix_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count,
    uint64_t nnz,
    const uint64_t* row_starts,
    const uint32_t* col_indices,
    const float* values,
    const float* sinogram,
    float* volume,
    int iterations, float relaxation,
    int projection_order_mode,
    const int* projection_order,
    int projection_order_length,
    const float* reconstruction_mask, const float* sinogram_mask,
    int use_min_constraint, float min_constraint,
    int use_max_constraint, float max_constraint)
{
	g_last_error.clear();
	if (!validate_sparse_matrix_inputs(volume_width, volume_height, angle_count, detector_count, nnz, row_starts, col_indices, values, sinogram, volume) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation) ||
	    !validate_projection_order_mode(projection_order_mode) ||
	    !validate_projection_order_list(projection_order_mode, projection_order, projection_order_length, angle_count)) {
		return 0;
	}
	try {
		BorrowedSparseMatrix sparse_matrix(
		    static_cast<unsigned int>(angle_count * detector_count),
		    static_cast<unsigned int>(volume_width * volume_height),
		    static_cast<unsigned long>(nnz),
		    values, col_indices, row_starts);
		astra::CSparseMatrixProjectionGeometry2D projection_geometry(angle_count, detector_count, &sparse_matrix);
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		if (!projection_geometry.isInitialized() || !volume_geometry.isInitialized()) return 0;
		astra::CSparseMatrixProjector2D proj(projection_geometry, volume_geometry);
		if (!proj.isInitialized()) {
			g_last_error = "failed to initialize sparse matrix projector";
			return 0;
		}
		return run_cpu_sart_2d(volume_geometry, projection_geometry, &proj, sinogram, volume, iterations, relaxation, projection_order_mode, projection_order, projection_order_length, angle_count, reconstruction_mask, sinogram_mask, use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_cgls2d_sparse_matrix_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count,
    uint64_t nnz,
    const uint64_t* row_starts,
    const uint32_t* col_indices,
    const float* values,
    const float* sinogram,
    float* volume,
    int iterations,
    const float* reconstruction_mask, const float* sinogram_mask,
    int use_min_constraint, float min_constraint,
    int use_max_constraint, float max_constraint)
{
	g_last_error.clear();
	if (!validate_sparse_matrix_inputs(volume_width, volume_height, angle_count, detector_count, nnz, row_starts, col_indices, values, sinogram, volume) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations)) {
		return 0;
	}
	try {
		BorrowedSparseMatrix sparse_matrix(
		    static_cast<unsigned int>(angle_count * detector_count),
		    static_cast<unsigned int>(volume_width * volume_height),
		    static_cast<unsigned long>(nnz),
		    values, col_indices, row_starts);
		astra::CSparseMatrixProjectionGeometry2D projection_geometry(angle_count, detector_count, &sparse_matrix);
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		if (!projection_geometry.isInitialized() || !volume_geometry.isInitialized()) return 0;
		astra::CSparseMatrixProjector2D proj(projection_geometry, volume_geometry);
		if (!proj.isInitialized()) {
			g_last_error = "failed to initialize sparse matrix projector";
			return 0;
		}
		return run_cpu_cgls_2d(volume_geometry, projection_geometry, &proj, sinogram, volume, iterations, reconstruction_mask, sinogram_mask, use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_art2d_sparse_matrix_f32(
    int volume_width, int volume_height,
    int angle_count, int detector_count,
    uint64_t nnz,
    const uint64_t* row_starts,
    const uint32_t* col_indices,
    const float* values,
    const float* sinogram,
    float* volume,
    int iterations, float relaxation,
    const float* reconstruction_mask, const float* sinogram_mask,
    int use_min_constraint, float min_constraint,
    int use_max_constraint, float max_constraint)
{
	g_last_error.clear();
	if (!validate_sparse_matrix_inputs(volume_width, volume_height, angle_count, detector_count, nnz, row_starts, col_indices, values, sinogram, volume) ||
	    !validate_optional_volume_mask(const_cast<float*>(reconstruction_mask), volume_width, volume_height) ||
	    !validate_optional_sinogram_mask(const_cast<float*>(sinogram_mask), detector_count, angle_count) ||
	    !validate_constraint_flag(use_min_constraint, "use_min_constraint") ||
	    !validate_constraint_flag(use_max_constraint, "use_max_constraint") ||
	    !validate_iterations(iterations) ||
	    !validate_relaxation(relaxation)) {
		return 0;
	}
	try {
		BorrowedSparseMatrix sparse_matrix(
		    static_cast<unsigned int>(angle_count * detector_count),
		    static_cast<unsigned int>(volume_width * volume_height),
		    static_cast<unsigned long>(nnz),
		    values, col_indices, row_starts);
		astra::CSparseMatrixProjectionGeometry2D projection_geometry(angle_count, detector_count, &sparse_matrix);
		astra::CVolumeGeometry2D volume_geometry; init_volume_geometry_2d(volume_geometry, volume_width, volume_height);
		if (!projection_geometry.isInitialized() || !volume_geometry.isInitialized()) return 0;
		astra::CSparseMatrixProjector2D proj(projection_geometry, volume_geometry);
		if (!proj.isInitialized()) {
			g_last_error = "failed to initialize sparse matrix projector";
			return 0;
		}
		return run_cpu_art_2d(volume_geometry, projection_geometry, &proj, sinogram, volume, iterations, relaxation, reconstruction_mask, sinogram_mask, use_min_constraint != 0, min_constraint, use_max_constraint != 0, max_constraint) ? 1 : 0;
	} catch (const std::exception& e) {
		g_last_error = e.what(); return 0;
	} catch (...) {
		g_last_error = "unknown exception"; return 0;
	}
}

extern "C" int astra_julia_cuda_dart_mask_2d_f32(
	float* mask,
	const float* segmentation,
	uint32_t conn,
	uint32_t radius,
	uint32_t threshold,
	uint32_t width,
	uint32_t height,
	int gpu_index)
{
	g_last_error.clear();
#ifndef ASTRA_CUDA
	g_last_error = "CUDA support not built in";
	return 0;
#else
	if (mask == nullptr || segmentation == nullptr || width == 0 || height == 0) {
		g_last_error = "invalid input pointers or dimensions";
		return 0;
	}
	if (conn != 4 && conn != 8) {
		g_last_error = "connectivity must be 4 or 8";
		return 0;
	}
	if (radius == 0 || threshold == 0) {
		g_last_error = "radius and threshold must be positive";
		return 0;
	}
	try {
		astraCUDA::setGPUIndex(gpu_index);
		astraCUDA::dartMask(mask, segmentation, conn, radius, threshold, width, height);
		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception in cuda dart mask 2d";
		return 0;
	}
#endif
}

extern "C" int astra_julia_cuda_dart_smoothing_2d_f32(
	float* out,
	const float* in,
	float b,
	uint32_t radius,
	uint32_t width,
	uint32_t height,
	int gpu_index)
{
	g_last_error.clear();
#ifndef ASTRA_CUDA
	g_last_error = "CUDA support not built in";
	return 0;
#else
	if (out == nullptr || in == nullptr || width == 0 || height == 0 || radius == 0) {
		g_last_error = "invalid input pointers or dimensions";
		return 0;
	}
	try {
		astraCUDA::setGPUIndex(gpu_index);
		astraCUDA::dartSmoothing(out, in, b, radius, width, height);
		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception in cuda dart smoothing 2d";
		return 0;
	}
#endif
}

extern "C" int astra_julia_cuda_roi_select_2d_f32(
	float* out,
	float radius,
	uint32_t width,
	uint32_t height,
	int gpu_index)
{
	g_last_error.clear();
#ifndef ASTRA_CUDA
	g_last_error = "CUDA support not built in";
	return 0;
#else
	if (out == nullptr || width == 0 || height == 0 || radius < 0.0f) {
		g_last_error = "invalid input pointers or radius";
		return 0;
	}
	try {
		astraCUDA::setGPUIndex(gpu_index);
		astraCUDA::roiSelect(out, radius, width, height);
		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception in cuda roi select 2d";
		return 0;
	}
#endif
}

extern "C" int astra_julia_cuda_dart_mask_3d_f32(
	float* mask,
	const float* segmentation,
	uint32_t conn,
	uint32_t radius,
	uint32_t threshold,
	uint32_t width,
	uint32_t height,
	uint32_t depth,
	int gpu_index)
{
	g_last_error.clear();
#ifndef ASTRA_CUDA
	g_last_error = "CUDA support not built in";
	return 0;
#else
	if (mask == nullptr || segmentation == nullptr || width == 0 || height == 0 || depth == 0) {
		g_last_error = "invalid input pointers or dimensions";
		return 0;
	}
	if (conn != 6 && conn != 26) {
		g_last_error = "3D connectivity must be 6 or 26";
		return 0;
	}
	if (radius == 0 || threshold == 0) {
		g_last_error = "radius and threshold must be positive";
		return 0;
	}
	try {
		astraCUDA3d::setGPUIndex(gpu_index);
		astra::SDimensions3D dims;
		dims.iVolX = width;
		dims.iVolY = height;
		dims.iVolZ = depth;
		dims.iProjAngles = 0;
		dims.iProjU = 0;
		dims.iProjV = 0;
		astraCUDA3d::dartMasking(mask, segmentation, conn, radius, threshold, dims);
		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception in cuda dart mask 3d";
		return 0;
	}
#endif
}

extern "C" int astra_julia_cuda_dart_smoothing_3d_f32(
	float* out,
	const float* in,
	float b,
	uint32_t radius,
	uint32_t width,
	uint32_t height,
	uint32_t depth,
	int gpu_index)
{
	g_last_error.clear();
#ifndef ASTRA_CUDA
	g_last_error = "CUDA support not built in";
	return 0;
#else
	if (out == nullptr || in == nullptr || width == 0 || height == 0 || depth == 0 || radius == 0) {
		g_last_error = "invalid input pointers or dimensions";
		return 0;
	}
	try {
		astraCUDA3d::setGPUIndex(gpu_index);
		astra::SDimensions3D dims;
		dims.iVolX = width;
		dims.iVolY = height;
		dims.iVolZ = depth;
		dims.iProjAngles = 0;
		dims.iProjU = 0;
		dims.iProjV = 0;
		astraCUDA3d::dartSmoothing(out, in, b, radius, dims);
		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception in cuda dart smoothing 3d";
		return 0;
	}
#endif
}

#ifdef ASTRA_CUDA
class CBorrowedDataMemory : public astra::CDataMemory<astra::float32> {
public:
	CBorrowedDataMemory(astra::float32* data) {
		m_bOwnData = false;
		m_pfData = data;
	}
};

static std::unique_ptr<astra::CProjectionGeometry3D> create_proj_geom_3d(const astra_julia_projection_part_t& p)
{
	std::unique_ptr<astra::CProjectionGeometry3D> geom;
	switch (p.geom_type) {
	case 0: { // Parallel3D
		if (p.angles == nullptr) {
			g_last_error = "angles pointer is null for parallel3d projection";
			return nullptr;
		}
		std::vector<astra::float32> angle_vec(p.angles, p.angles + p.proj_count);
		geom = std::make_unique<astra::CParallelProjectionGeometry3D>(
			p.proj_count, p.det_row_count, p.det_col_count,
			p.det_width, p.det_height, std::move(angle_vec)
		);
		break;
	}
	case 1: { // ParallelVec3D
		if (p.vectors == nullptr) {
			g_last_error = "vectors pointer is null for parallel_vec3d projection";
			return nullptr;
		}
		auto vecs = build_parallel_vec_geometry(p.proj_count, p.det_col_count, p.det_row_count, p.vectors);
		geom = std::make_unique<astra::CParallelVecProjectionGeometry3D>(
			p.proj_count, p.det_row_count, p.det_col_count, std::move(vecs)
		);
		break;
	}
	case 2: { // Cone3D
		if (p.angles == nullptr) {
			g_last_error = "angles pointer is null for cone3d projection";
			return nullptr;
		}
		std::vector<astra::float32> angle_vec(p.angles, p.angles + p.proj_count);
		geom = std::make_unique<astra::CConeProjectionGeometry3D>(
			p.proj_count, p.det_row_count, p.det_col_count,
			p.det_width, p.det_height, std::move(angle_vec),
			p.src_origin, p.origin_det
		);
		break;
	}
	case 3: { // ConeVec3D
		if (p.vectors == nullptr) {
			g_last_error = "vectors pointer is null for cone_vec3d projection";
			return nullptr;
		}
		auto vecs = build_cone_vec_geometry(p.proj_count, p.det_col_count, p.det_row_count, p.vectors);
		geom = std::make_unique<astra::CConeVecProjectionGeometry3D>(
			p.proj_count, p.det_row_count, p.det_col_count, std::move(vecs)
		);
		break;
	}
	case 4: { // CylConeVec3D
		if (p.vectors == nullptr) {
			g_last_error = "vectors pointer is null for cyl_cone_vec3d projection";
			return nullptr;
		}
		auto vecs = build_cyl_cone_vec_geometry(p.proj_count, p.vectors);
		geom = std::make_unique<astra::CCylConeVecProjectionGeometry3D>(
			p.proj_count, p.det_row_count, p.det_col_count, std::move(vecs)
		);
		break;
	}
	default:
		g_last_error = "unsupported projection geometry type in composite job";
		return nullptr;
	}

	if (!geom || !geom->isInitialized()) {
		g_last_error = "failed to initialize projection geometry for composite job";
		return nullptr;
	}
	return geom;
}

static bool setup_composite_objects(
	int num_volumes,
	const astra_julia_volume_part_t* volumes,
	int num_projections,
	const astra_julia_projection_part_t* projections,
	std::vector<astra::CFloat32VolumeData3D*>& vol_ptrs,
	std::vector<astra::CFloat32ProjectionData3D*>& proj_ptrs)
{
	if (num_volumes <= 0 || volumes == nullptr) {
		g_last_error = "num_volumes must be > 0 and volumes must not be null";
		return false;
	}
	if (num_projections <= 0 || projections == nullptr) {
		g_last_error = "num_projections must be > 0 and projections must not be null";
		return false;
	}

	for (int i = 0; i < num_volumes; ++i) {
		const auto& v = volumes[i];
		if (v.data == nullptr) {
			g_last_error = "volume part data pointer is null";
			return false;
		}
		auto geom = std::make_unique<astra::CVolumeGeometry3D>(
			v.grid_col_count, v.grid_row_count, v.grid_slice_count,
			v.min_x, v.min_y, v.min_z, v.max_x, v.max_y, v.max_z
		);
		if (!geom->isInitialized()) {
			g_last_error = "failed to initialize volume geometry for composite job";
			return false;
		}
		auto storage = new CBorrowedDataMemory(v.data);
		auto vol_obj = new astra::CFloat32VolumeData3D(std::move(geom), storage);
		vol_ptrs.push_back(vol_obj);
	}

	for (int i = 0; i < num_projections; ++i) {
		const auto& p = projections[i];
		if (p.data == nullptr) {
			g_last_error = "projection part data pointer is null";
			return false;
		}
		auto geom = create_proj_geom_3d(p);
		if (!geom) {
			return false;
		}
		auto storage = new CBorrowedDataMemory(p.data);
		auto proj_obj = new astra::CFloat32ProjectionData3D(std::move(geom), storage);
		proj_ptrs.push_back(proj_obj);
	}

	return true;
}
#endif

extern "C" int astra_julia_cuda_composite_fp3d_f32(
	int num_volumes,
	const astra_julia_volume_part_t* volumes,
	int num_projections,
	const astra_julia_projection_part_t* projections,
	int mode,
	int gpu_index)
{
	g_last_error.clear();
#ifndef ASTRA_CUDA
	(void)num_volumes;
	(void)volumes;
	(void)num_projections;
	(void)projections;
	(void)mode;
	(void)gpu_index;
	g_last_error = "CUDA support not built in";
	return 0;
#else
	std::vector<astra::CFloat32VolumeData3D*> vol_ptrs;
	std::vector<astra::CFloat32ProjectionData3D*> proj_ptrs;

	auto cleanup = [&]() {
		for (auto* ptr : vol_ptrs) delete ptr;
		for (auto* ptr : proj_ptrs) delete ptr;
		vol_ptrs.clear();
		proj_ptrs.clear();
	};

	try {
		if (!setup_composite_objects(num_volumes, volumes, num_projections, projections, vol_ptrs, proj_ptrs)) {
			cleanup();
			return 0;
		}

		astra::CCompositeGeometryManager cgm;
		if (gpu_index >= 0) {
			cgm.setGPUIndices({gpu_index});
		}
		auto emode = (mode == 0)
			? astra::CCompositeGeometryManager::MODE_ADD
			: astra::CCompositeGeometryManager::MODE_SET;

		bool ok = cgm.doFP(nullptr, vol_ptrs, proj_ptrs, emode);
		cleanup();
		if (!ok) {
			g_last_error = "CCompositeGeometryManager::doFP failed";
			return 0;
		}
		return 1;
	} catch (const std::exception& e) {
		cleanup();
		g_last_error = e.what();
		return 0;
	} catch (...) {
		cleanup();
		g_last_error = "unknown exception in composite fp3d";
		return 0;
	}
#endif
}

extern "C" int astra_julia_cuda_composite_bp3d_f32(
	int num_volumes,
	const astra_julia_volume_part_t* volumes,
	int num_projections,
	const astra_julia_projection_part_t* projections,
	int mode,
	int gpu_index)
{
	g_last_error.clear();
#ifndef ASTRA_CUDA
	(void)num_volumes;
	(void)volumes;
	(void)num_projections;
	(void)projections;
	(void)mode;
	(void)gpu_index;
	g_last_error = "CUDA support not built in";
	return 0;
#else
	std::vector<astra::CFloat32VolumeData3D*> vol_ptrs;
	std::vector<astra::CFloat32ProjectionData3D*> proj_ptrs;

	auto cleanup = [&]() {
		for (auto* ptr : vol_ptrs) delete ptr;
		for (auto* ptr : proj_ptrs) delete ptr;
		vol_ptrs.clear();
		proj_ptrs.clear();
	};

	try {
		if (!setup_composite_objects(num_volumes, volumes, num_projections, projections, vol_ptrs, proj_ptrs)) {
			cleanup();
			return 0;
		}

		astra::CCompositeGeometryManager cgm;
		if (gpu_index >= 0) {
			cgm.setGPUIndices({gpu_index});
		}
		auto emode = (mode == 0)
			? astra::CCompositeGeometryManager::MODE_ADD
			: astra::CCompositeGeometryManager::MODE_SET;

		bool ok = cgm.doBP(nullptr, vol_ptrs, proj_ptrs, emode);
		cleanup();
		if (!ok) {
			g_last_error = "CCompositeGeometryManager::doBP failed";
			return 0;
		}
		return 1;
	} catch (const std::exception& e) {
		cleanup();
		g_last_error = e.what();
		return 0;
	} catch (...) {
		cleanup();
		g_last_error = "unknown exception in composite bp3d";
		return 0;
	}
#endif
}

extern "C" int astra_julia_project_point_3d(
	const astra_julia_projection_part_t* proj,
	double x, double y, double z,
	int angle_idx,
	double* out_u, double* out_v)
{
	g_last_error.clear();
	if (proj == nullptr || out_u == nullptr || out_v == nullptr) {
		g_last_error = "null pointer passed to project_point_3d";
		return 0;
	}
	try {
		auto geom = create_proj_geom_3d(*proj);
		if (!geom) {
			return 0;
		}
		if (angle_idx < 0 || angle_idx >= geom->getProjectionCount()) {
			g_last_error = "angle_idx out of range in project_point_3d";
			return 0;
		}
		geom->projectPoint(x, y, z, angle_idx, *out_u, *out_v);
		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception in project_point_3d";
		return 0;
	}
}

extern "C" int astra_julia_projected_bbox_3d(
	const astra_julia_projection_part_t* proj,
	double min_x, double max_x,
	double min_y, double max_y,
	double min_z, double max_z,
	int angle_idx,
	double* out_min_u, double* out_max_u,
	double* out_min_v, double* out_max_v)
{
	g_last_error.clear();
	if (proj == nullptr || out_min_u == nullptr || out_max_u == nullptr || out_min_v == nullptr || out_max_v == nullptr) {
		g_last_error = "null pointer passed to projected_bbox_3d";
		return 0;
	}
	try {
		auto geom = create_proj_geom_3d(*proj);
		if (!geom) {
			return 0;
		}
		if (angle_idx < 0) {
			geom->getProjectedBBox(min_x, max_x, min_y, max_y, min_z, max_z,
			                       *out_min_u, *out_max_u, *out_min_v, *out_max_v);
		} else {
			if (angle_idx >= geom->getProjectionCount()) {
				g_last_error = "angle_idx out of range in projected_bbox_3d";
				return 0;
			}
			geom->getProjectedBBoxSingleAngle(angle_idx, min_x, max_x, min_y, max_y, min_z, max_z,
			                                  *out_min_u, *out_max_u, *out_min_v, *out_max_v);
		}
		return 1;
	} catch (const std::exception& e) {
		g_last_error = e.what();
		return 0;
	} catch (...) {
		g_last_error = "unknown exception in projected_bbox_3d";
		return 0;
	}
}

extern "C" const char* astra_julia_last_error(void)
{
	return g_last_error.c_str();
}
