cmake_minimum_required(VERSION 3.15)
project(cimnodes_editor CXX)

set(CMAKE_CXX_STANDARD 14)
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

add_library(cimnodes_editor SHARED
    cimnodes_editor/cimnodes_editor.cpp
    cimnodes_editor/imgui-node-editor/crude_json.cpp
    cimnodes_editor/imgui-node-editor/imgui_canvas.cpp
    cimnodes_editor/imgui-node-editor/imgui_node_editor.cpp
    cimnodes_editor/imgui-node-editor/imgui_node_editor_api.cpp
)

target_include_directories(cimnodes_editor PRIVATE
    ${CIMGUI_INCLUDE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/cimnodes_editor
    ${CMAKE_CURRENT_SOURCE_DIR}/cimnodes_editor/imgui-node-editor
)

# Need to keep these in sync with JuliaImGui/cimgui-pack's CMakeLists.txt
# (target_compile_definitions section).
target_compile_definitions(cimnodes_editor PRIVATE
    IMGUI_DISABLE_OBSOLETE_FUNCTIONS=1
    IMGUI_ENABLE_TEST_ENGINE
)

target_link_libraries(cimnodes_editor PRIVATE ${CIMGUI_LIBRARY})

install(TARGETS cimnodes_editor
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib)

install(FILES
        cimnodes_editor/cimnodes_editor.h
        DESTINATION include)
