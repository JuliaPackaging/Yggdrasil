cmake_policy(SET CMP0025 NEW)
project(jinja2cpp_wrapper)

cmake_minimum_required(VERSION 3.14)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

find_package(JlCxx)
include_directories(${JlCxx_INCLUDE_DIRS})
get_target_property(JlCxx_location JlCxx::cxxwrap_julia LOCATION)
get_filename_component(JlCxx_location ${JlCxx_location} DIRECTORY)
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib;${JlCxx_location}")

message(STATUS "Found JlCxx at ${JlCxx_location}")

find_library(JIN2JA_LIBRARY jinja2cpp REQUIRED)

message(STATUS "Found jinja2cpp at ${JIN2JA_LIBRARY}")

add_library(jinja2cpp_wrapper SHARED jinja2cpp_wrapper.cpp)

target_link_libraries(jinja2cpp_wrapper JlCxx::cxxwrap_julia ${JIN2JA_LIBRARY})

install(TARGETS
 jinja2cpp_wrapper
LIBRARY DESTINATION lib
ARCHIVE DESTINATION lib
RUNTIME DESTINATION lib)