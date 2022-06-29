cmake_minimum_required(VERSION 3.14)
cmake_policy(SET CMP0025 NEW)

project(GeographicLibWrapper)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

find_package(JlCxx REQUIRED)
get_target_property(JlCxx_location JlCxx::cxxwrap_julia LOCATION)
get_filename_component(JlCxx_location ${JlCxx_location} DIRECTORY)
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib;${JlCxx_location}")

message(STATUS "Found JlCxx at ${JlCxx_location}")

find_package(GeographicLib REQUIRED)

add_library(GeographicLibWrapper SHARED GeographicLibWrapper.cpp)

target_include_directories(GeographicLibWrapper PUBLIC
    "${Julia_INCLUDE_DIRS}"
    "${GeographicLib_INCLUDE_DIRS}")

target_link_libraries(GeographicLibWrapper
    JlCxx::cxxwrap_julia
    "${GeographicLib_LIBRARIES}")

install(TARGETS GeographicLibWrapper LIBRARY)
