cmake_minimum_required(VERSION 3.15)

project(slopejll)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_BUILD_TYPE Release)

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

find_package(Eigen3 3.4 REQUIRED NO_MODULE)
find_package(OpenMP)

find_package(JlCxx)
get_target_property(JlCxx_location JlCxx::cxxwrap_julia LOCATION)
get_filename_component(JlCxx_location ${JlCxx_location} DIRECTORY)
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib;${JlCxx_location}")

if(OPENMP_FOUND)
    message(STATUS "OpenMP found")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
endif()

find_library(SLOPE_LIBRARY slope REQUIRED)

add_library(${PROJECT_NAME} SHARED slopejll.cpp)

target_link_libraries(
    ${PROJECT_NAME}
    PUBLIC JlCxx::cxxwrap_julia Eigen3::Eigen ${SLOPE_LIBRARY}
)

install(TARGETS ${PROJECT_NAME} LIBRARY)
