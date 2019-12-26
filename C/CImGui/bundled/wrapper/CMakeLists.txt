cmake_minimum_required(VERSION 3.8.0)
project(cimgui)

add_library(cimgui SHARED)

target_sources(cimgui PRIVATE cimgui.cpp)
target_sources(cimgui PRIVATE ./imgui/imgui.cpp)
target_sources(cimgui PRIVATE ./imgui/imgui_draw.cpp)
target_sources(cimgui PRIVATE ./imgui/imgui_demo.cpp)
target_sources(cimgui PRIVATE ./imgui/imgui_widgets.cpp)

target_include_directories(cimgui PUBLIC ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/imgui)

add_definitions("-DIMGUI_DISABLE_OBSOLETE_FUNCTIONS=1")

if (WIN32)
    add_definitions("-DIMGUI_IMPL_API=extern \"C\" __declspec\(dllexport\)")
else(WIN32)
    add_definitions("-DIMGUI_IMPL_API=extern \"C\" ")
endif(WIN32)

set_target_properties(cimgui PROPERTIES PUBLIC_HEADER cimgui.h)

install(TARGETS cimgui
        EXPORT cimgui-targets
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
        PUBLIC_HEADER DESTINATION include)

add_library(cimgui_helper SHARED helper.c)

target_include_directories(cimgui_helper PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(cimgui_helper cimgui)
set_target_properties(cimgui_helper PROPERTIES PUBLIC_HEADER helper.h)

install(TARGETS cimgui_helper
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib/static
        INCLUDES DESTINATION include
        PUBLIC_HEADER DESTINATION include)
