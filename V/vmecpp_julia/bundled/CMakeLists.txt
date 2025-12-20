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
find_package(netCDF REQUIRED)
find_package(OpenMP REQUIRED)
find_package(BLAS REQUIRED)
find_package(LAPACK REQUIRED)

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
