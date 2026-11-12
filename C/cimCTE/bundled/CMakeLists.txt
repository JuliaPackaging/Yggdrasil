cmake_minimum_required(VERSION 3.15)
project(cimCTE CXX)

set(CMAKE_CXX_STANDARD 17)
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

add_library(cimCTE SHARED
    cimCTE/cimCTE.cpp
    cimCTE/ImGuiColorTextEdit/TextEditor.cpp
    cimCTE/ImGuiColorTextEdit/TextDiff.cpp
    cimCTE/ImGuiColorTextEdit/extras/TrieAutoComplete.cpp
    cimCTE/ImGuiColorTextEdit/example/dejavu.cpp
    cimCTE/ImGuiColorTextEdit/example/notosans.cpp
)

target_include_directories(cimCTE PRIVATE
    ${CIMGUI_INCLUDE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/cimCTE
    ${CMAKE_CURRENT_SOURCE_DIR}/cimCTE/ImGuiColorTextEdit
)

# Need to keep these in sync with JuliaImGui/cimgui-pack's CMakeLists.txt
# (target_compile_definitions section).
target_compile_definitions(cimCTE PRIVATE
    IMGUI_DISABLE_OBSOLETE_FUNCTIONS=1
    IMGUI_ENABLE_TEST_ENGINE
    IMGUI_ENABLE_FREETYPE
    IMGUI_USE_WCHAR32
)

target_link_libraries(cimCTE PRIVATE ${CIMGUI_LIBRARY})

install(TARGETS cimCTE
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib)

install(FILES
        cimCTE/cimCTE.h
        DESTINATION include)
