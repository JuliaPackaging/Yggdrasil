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

# BLAS/LAPACK: Use libblastrampoline to allow users to choose their BLAS implementation
# The library name is passed via LBT environment variable (blastrampoline on Unix, blastrampoline-5 on Windows)
set(LBT_NAME "$ENV{LBT}")
if(NOT LBT_NAME)
    set(LBT_NAME "blastrampoline")
endif()

# Get the library directory from netCDF location
get_filename_component(NETCDF_LIB_DIR "${NETCDF_LIBRARY}" DIRECTORY)
message(STATUS "Searching for libblastrampoline (${LBT_NAME}) in: ${NETCDF_LIB_DIR}")

find_library(LBT_LIBRARY
    NAMES ${LBT_NAME}
    HINTS "${NETCDF_LIB_DIR}"
    NO_DEFAULT_PATH)
if(NOT LBT_LIBRARY)
    find_library(LBT_LIBRARY
        NAMES ${LBT_NAME}
        PATHS "${NETCDF_LIB_DIR}" "${CMAKE_PREFIX_PATH}/lib" "$ENV{prefix}/lib"
        PATH_SUFFIXES lib lib64)
endif()

if(LBT_LIBRARY)
    message(STATUS "Found libblastrampoline: ${LBT_LIBRARY}")
    set(BLAS_LIBRARIES ${LBT_LIBRARY})
    set(LAPACK_LIBRARIES ${LBT_LIBRARY})
else()
    message(WARNING "Could not find libblastrampoline, linking without BLAS/LAPACK")
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
