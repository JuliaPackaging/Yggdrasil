cmake_minimum_required(VERSION 3.15)
project(cimplot3d CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# CImGuiPack_jll exports a cmake target `cimgui::cimgui` via its
# lib/cmake/cimgui/cimgui-config.cmake. Use it so headers, link line and
# IMPORTED_LOCATION / SONAME are all picked up portably.
find_package(cimgui REQUIRED)

add_library(cimplot3d SHARED
    cimplot3d/cimplot3d.cpp
    cimplot3d/implot3d/implot3d.cpp
    cimplot3d/implot3d/implot3d_items.cpp
    cimplot3d/implot3d/implot3d_meshes.cpp
    cimplot3d/implot3d/implot3d_demo.cpp
)

target_include_directories(cimplot3d PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/cimplot3d
    ${CMAKE_CURRENT_SOURCE_DIR}/cimplot3d/implot3d
)

# These MUST match the flags CImGuiPack was built with; otherwise
# ImGuiContext / ImGuiIO struct layouts diverge and ImPlot3D::BeginPlot
# dereferences garbage. Keep in sync with JuliaImGui/cimgui-pack
# CMakeLists.txt (target_compile_definitions section).
target_compile_definitions(cimplot3d PRIVATE
    IMGUI_DISABLE_OBSOLETE_FUNCTIONS=1
    IMGUI_ENABLE_TEST_ENGINE
)

target_link_libraries(cimplot3d PRIVATE cimgui::cimgui)

install(TARGETS cimplot3d
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib)

install(FILES
        cimplot3d/cimplot3d.h
        DESTINATION include)

install(FILES
        cimplot3d/implot3d/implot3d.h
        cimplot3d/implot3d/implot3d_internal.h
        DESTINATION include/implot3d)
