cmake_minimum_required(VERSION 3.1)

project(accerionbindings)
# Cmake policies
# ==============
if(POLICY CMP0074)
    # find_package() uses <PackageName>_ROOT variables.
    # This policy was introduced in CMake version 3.12.
    cmake_policy(SET CMP0074 NEW)
endif()


set(CMAKE_MACOSX_RPATH 1)

set(CMAKE_CXX_STANDARD 17)
add_definitions(-DJULIA_ENABLE_THREADING)

find_package(JlCxx REQUIRED)
find_package(AccerionSensorAPI REQUIRED)

get_target_property(JlCxx_location JlCxx::cxxwrap_julia LOCATION)
get_filename_component(JlCxx_location ${JlCxx_location} DIRECTORY)
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib;${JlCxx_location}")

message(STATUS "Found JlCxx at ${JlCxx_location}")

add_library(accerionbindings SHARED accerionbindings.cpp)

set(TARGET_NAME accerionbindings)

target_link_libraries(accerionbindings
    AccerionSensorAPI
    JlCxx::cxxwrap_julia
    JlCxx::cxxwrap_julia_stl
    )

# target_compile_features(${TARGET_NAME} PRIVATE cxx_std_17)

install(TARGETS
  accerionbindings
LIBRARY DESTINATION lib
ARCHIVE DESTINATION lib
RUNTIME DESTINATION lib)
