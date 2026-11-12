cmake_minimum_required(VERSION 3.10)
project(hello_world C)

find_package(MPI REQUIRED)

add_executable(hello_world hello_world.c)
target_link_libraries(hello_world PRIVATE MPI::MPI_C)

install(TARGETS hello_world RUNTIME DESTINATION bin)
