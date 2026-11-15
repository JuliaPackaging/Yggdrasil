cmake_minimum_required(VERSION 3.13)
project(hello_cxxwrap LANGUAGES CXX)
find_package(JlCxx REQUIRED)

add_library(hello_cxxwrap SHARED hello_cxxwrap.cpp)
target_link_libraries(hello_cxxwrap PRIVATE JlCxx::cxxwrap_julia)

install(TARGETS hello_cxxwrap
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin)
