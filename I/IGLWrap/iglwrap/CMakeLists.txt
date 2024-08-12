cmake_minimum_required(VERSION 3.16)
project(iglwrap)

list(PREPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

# Libigl
option(LIBIGL_WITH_OPENGL            "Use OpenGL"         OFF)
option(LIBIGL_WITH_OPENGL_GLFW       "Use GLFW"           OFF)
option(LIBIGL_COPYLEFT_CGAL          "Use CGAL"           ON)
#  option(BUILD_SHARED_LIBRARIES "Build shared libs" ON)
include(libigl)
#  set(CMAKE_BUILD_TYPE Debug)
#  set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -O0")
#  set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -O0")

# Add your project files
#  file(GLOB SRC_FILES *.cpp)
#  add_executable(${PROJECT_NAME} ${SRC_FILES})
#  target_link_libraries(${PROJECT_NAME} PUBLIC igl::core igl::opengl_glfw)
#  file(GLOB SRC_FILES *.cpp)
add_library(${PROJECT_NAME} SHARED iglwrap.cpp)
#  set_target_properties(${PROJECT_NAME} PROPERTIES PUBLIC_HEADER iglwrap.h)
target_link_libraries(${PROJECT_NAME} PUBLIC igl::core igl_copyleft::cgal)
install(TARGETS ${PROJECT_NAME} LIBRARY)
