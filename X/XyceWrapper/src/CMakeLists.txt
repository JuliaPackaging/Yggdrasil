cmake_policy(SET CMP0025 NEW)
project(XyceLib)

cmake_minimum_required(VERSION 3.14)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

find_package(JlCxx)
get_target_property(JlCxx_location JlCxx::cxxwrap_julia LOCATION)
get_filename_component(JlCxx_location ${JlCxx_location} DIRECTORY)
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib;${JlCxx_location}")

message(STATUS "Found JlCxx at ${JlCxx_location}")

find_library(XYCE_LIBRARY xyce REQUIRED)

message(STATUS "Found Xyce at ${XYCE_LIBRARY}")

add_library(xycelib SHARED xycelib.cpp)

target_link_libraries(xycelib
  JlCxx::cxxwrap_julia
  ${XYCE_LIBRARY}
  teuchoscore
)

install(TARGETS xycelib LIBRARY)
