cmake_minimum_required(VERSION 3.18)
project(hello_cuda LANGUAGES CXX CUDA)
find_package(CUDAToolkit REQUIRED)

add_library(hello_cuda SHARED hello_cuda.cu)
target_link_libraries(hello_cuda PRIVATE CUDA::cublas)

add_executable(hello_world_cuda main.cpp)
target_link_libraries(hello_world_cuda PRIVATE hello_cuda)
set_target_properties(hello_world_cuda PROPERTIES BUILD_RPATH_USE_ORIGIN ON)

install(TARGETS hello_cuda hello_world_cuda)
