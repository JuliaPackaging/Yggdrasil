cmake_minimum_required(VERSION 3.8.0)
project(cimplot)

SET(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(imgui-cpp REQUIRED)

add_library(cimplot SHARED)

target_sources(cimplot PRIVATE ./cimplot.cpp)
target_sources(cimplot PRIVATE ./implot/implot.cpp)
target_sources(cimplot PRIVATE ./implot/implot_demo.cpp)

target_include_directories(cimplot PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/implot ${CMAKE_CURRENT_SOURCE_DIR}/../imgui)

set_target_properties(cimplot PROPERTIES PUBLIC_HEADER ${CMAKE_CURRENT_SOURCE_DIR}/cimplot.h)
target_compile_features(cimplot PRIVATE cxx_std_11)
target_link_libraries(cimplot imgui-cpp)

install(TARGETS cimplot
        EXPORT cimplot-targets
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
        PUBLIC_HEADER DESTINATION include)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/compile_commands.json DESTINATION share)
