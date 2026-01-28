cmake_minimum_required(VERSION 3.18)

project(vmecpp_julia CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# ============================================
# Find JlCxx (CxxWrap) - provides Julia bindings
# ============================================
find_package(JlCxx REQUIRED)

# Add JlCxx cmake modules to module path for FindJulia
list(APPEND CMAKE_MODULE_PATH "${JlCxx_DIR}")

# ============================================
# External paths (set by build script)
# ============================================
set(VMECPP_SOURCE_DIR "" CACHE PATH "Path to VMECPP source directory")
set(VMECPP_BUILD_DIR "" CACHE PATH "Path to VMECPP build directory")
set(EIGEN_DIR "" CACHE PATH "Path to Eigen headers")

if(NOT VMECPP_SOURCE_DIR)
    message(FATAL_ERROR "VMECPP_SOURCE_DIR must be set")
endif()
if(NOT VMECPP_BUILD_DIR)
    message(FATAL_ERROR "VMECPP_BUILD_DIR must be set")
endif()

message(STATUS "VMECPP source directory: ${VMECPP_SOURCE_DIR}")
message(STATUS "VMECPP build directory: ${VMECPP_BUILD_DIR}")

# ============================================
# Find dependencies from JLL packages
# ============================================
find_package(HDF5 REQUIRED COMPONENTS CXX)

# netCDF: Try find_package first, fall back to finding the library directly
find_package(netCDF QUIET CONFIG)
if(NOT netCDF_FOUND)
    # NetCDF_jll doesn't provide cmake config files, find library directly
    find_library(NETCDF_LIBRARY NAMES netcdf REQUIRED)
    find_path(NETCDF_INCLUDE_DIR netcdf.h REQUIRED)
    message(STATUS "Found netCDF library: ${NETCDF_LIBRARY}")
    message(STATUS "Found netCDF include: ${NETCDF_INCLUDE_DIR}")
    # Create an imported target for consistency
    add_library(netCDF::netcdf UNKNOWN IMPORTED)
    set_target_properties(netCDF::netcdf PROPERTIES
        IMPORTED_LOCATION "${NETCDF_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${NETCDF_INCLUDE_DIR}"
    )
else()
    message(STATUS "Found netCDF via cmake config")
endif()

find_package(OpenMP REQUIRED)

# BLAS/LAPACK: Find OpenBLAS in the sysroot (same location as netCDF)
# Get the directory where netCDF was found and use it for OpenBLAS
get_filename_component(NETCDF_LIB_DIR "${NETCDF_LIBRARY}" DIRECTORY)
message(STATUS "Searching for OpenBLAS in: ${NETCDF_LIB_DIR}")

# On macOS, also check for .dylib extension explicitly
find_library(OPENBLAS_LIBRARY
    NAMES openblas libopenblas
    HINTS "${NETCDF_LIB_DIR}"
    NO_DEFAULT_PATH)
if(NOT OPENBLAS_LIBRARY)
    # Fall back to searching normally with PATHS
    find_library(OPENBLAS_LIBRARY
        NAMES openblas libopenblas
        PATHS "${NETCDF_LIB_DIR}" "${CMAKE_PREFIX_PATH}/lib" "$ENV{prefix}/lib"
        PATH_SUFFIXES lib lib64)
endif()

# On macOS, also try to find the Accelerate framework as fallback
if(NOT OPENBLAS_LIBRARY AND APPLE)
    find_library(ACCELERATE_FRAMEWORK Accelerate)
    if(ACCELERATE_FRAMEWORK)
        message(STATUS "Using macOS Accelerate framework for BLAS/LAPACK")
        set(BLAS_LIBRARIES ${ACCELERATE_FRAMEWORK})
        set(LAPACK_LIBRARIES ${ACCELERATE_FRAMEWORK})
    else()
        message(WARNING "Could not find OpenBLAS or Accelerate framework")
        set(BLAS_LIBRARIES "")
        set(LAPACK_LIBRARIES "")
    endif()
elseif(OPENBLAS_LIBRARY)
    message(STATUS "Found OpenBLAS library: ${OPENBLAS_LIBRARY}")
    set(BLAS_LIBRARIES ${OPENBLAS_LIBRARY})
    set(LAPACK_LIBRARIES ${OPENBLAS_LIBRARY})
else()
    # vmecpp_core doesn't actually require OpenBLAS at link time if BLAS is built into system
    message(WARNING "Could not find OpenBLAS library, trying to skip BLAS/LAPACK linking")
    set(BLAS_LIBRARIES "")
    set(LAPACK_LIBRARIES "")
endif()

# Find Abseil (installed by build script)
find_package(absl REQUIRED)

# ============================================
# Create the Julia wrapper shared library
# ============================================
add_library(vmecpp_julia SHARED
    vmecpp_julia.cpp
)

# Include directories
target_include_directories(vmecpp_julia PRIVATE
    ${VMECPP_SOURCE_DIR}/src/vmecpp/cpp
    ${EIGEN_DIR}
)

# Get all abseil libraries we need
set(ABSL_LIBS
    absl::status
    absl::statusor
    absl::strings
    absl::str_format
    absl::log
    absl::check
    absl::base
    absl::synchronization
)

# Link libraries
target_link_libraries(vmecpp_julia
    PUBLIC
        JlCxx::cxxwrap_julia
        ${VMECPP_BUILD_DIR}/libvmecpp_core.a
        ${ABSL_LIBS}
        HDF5::HDF5
        netCDF::netcdf
        OpenMP::OpenMP_CXX
        ${LAPACK_LIBRARIES}
        ${BLAS_LIBRARIES}
)

# ============================================
# Installation
# ============================================
install(TARGETS vmecpp_julia
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)
