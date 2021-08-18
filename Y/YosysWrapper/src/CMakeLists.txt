project(YosysWrapper)

cmake_minimum_required(VERSION 2.8.12)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

include_directories(${INTERFACE_INCLUDE_DIRECTORIES})

find_package(JlCxx)
get_target_property(JlCxx_location JlCxx::cxxwrap_julia LOCATION)
get_filename_component(JlCxx_location ${JlCxx_location} DIRECTORY)
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib;${JlCxx_location};${CMAKE_INSTALL_PREFIX}/lib/yosys")
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

message(STATUS "Found JlCxx at ${JlCxx_location}")

find_library(LIBYOSYS yosys REQUIRED)

message(STATUS "Found Yosys at ${LIBYOSYS}")

add_library(yosyswrapper SHARED yosyswrapper.cpp)

include_directories(${CMAKE_INSTALL_PREFIX}/share/yosys/include)

target_link_libraries(yosyswrapper
  JlCxx::cxxwrap_julia
  ${LIBYOSYS}
)

# Note: it is important these defines match the ones in the Makefile of Yosys_jll
add_definitions(-D_YOSYS_)
add_definitions(-DYOSYS_ENABLE_TCL)
add_definitions(-DYOSYS_ENABLE_PLUGINS)
add_definitions(-DYOSYS_ENABLE_READLINE)


install(TARGETS
  yosyswrapper
LIBRARY DESTINATION lib
ARCHIVE DESTINATION lib
RUNTIME DESTINATION lib)
