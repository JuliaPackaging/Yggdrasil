cmake_minimum_required(VERSION 3.15)
project(cimplot3d CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Locate libcimgui (from CImGuiPack_jll) and its public headers directly,
# rather than via find_package(cimgui). The exported cmake target
# pulls in JlCxx::cxxwrap_julia in its INTERFACE_LINK_LIBRARIES on some
# platforms; we don't use any cxxwrap symbols so we'd rather not depend
# on JlCxx at build time.
find_path(CIMGUI_INCLUDE_DIR cimgui.h REQUIRED)
find_library(CIMGUI_LIBRARY NAMES cimgui REQUIRED)
message(STATUS "Using cimgui: ${CIMGUI_LIBRARY} (headers in ${CIMGUI_INCLUDE_DIR})")

add_library(cimplot3d SHARED
    cimplot3d/cimplot3d.cpp
    cimplot3d/implot3d/implot3d.cpp
    cimplot3d/implot3d/implot3d_items.cpp
    cimplot3d/implot3d/implot3d_meshes.cpp
    cimplot3d/implot3d/implot3d_demo.cpp
)

target_include_directories(cimplot3d PRIVATE
    ${CIMGUI_INCLUDE_DIR}
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

target_link_libraries(cimplot3d PRIVATE ${CIMGUI_LIBRARY})

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
