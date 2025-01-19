cmake_policy(SET CMP0025 NEW)
project(ITKIOWrapper)

cmake_minimum_required(VERSION 3.14)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

find_package(JlCxx)
include_directories(${JlCxx_INCLUDE_DIRS})
get_target_property(JlCxx_location JlCxx::cxxwrap_julia LOCATION)
get_filename_component(JlCxx_location ${JlCxx_location} DIRECTORY)
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib;${JlCxx_location}")

message(STATUS "Found JlCxx at ${JlCxx_location}")

# Update the ITK components list
set(ITK_COMPONENTS
    ITKCommon
    ITKIOImageBase
    ITKIOGDCM
    ITKIONIFTI
    ITKIONRRD
    ITKIOHDF5
    ITKIOMeta
    ITKIOPNG
    ITKIOTIFF
    ITKImageIO
)

find_package(ITK REQUIRED COMPONENTS ${ITK_COMPONENTS})
include(${ITK_USE_FILE})

message(STATUS "Found ITK at ${ITK_USE_FILE}")

add_library(ITKIOWrapper SHARED itklib.cpp)

target_link_libraries(ITKIOWrapper
  JlCxx::cxxwrap_julia
  ${ITK_LIBRARIES}
)

install(TARGETS ITKIOWrapper LIBRARY)
