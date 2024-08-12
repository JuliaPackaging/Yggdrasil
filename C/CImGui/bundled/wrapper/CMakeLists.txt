cmake_minimum_required(VERSION 3.8.0)
project(cimgui)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_library(imgui-cpp SHARED)

target_sources(imgui-cpp PRIVATE ./imgui/imgui.cpp)
target_sources(imgui-cpp PRIVATE ./imgui/imgui_draw.cpp)
target_sources(imgui-cpp PRIVATE ./imgui/imgui_demo.cpp)
target_sources(imgui-cpp PRIVATE ./imgui/imgui_widgets.cpp)

target_include_directories(imgui-cpp PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/imgui>
        $<INSTALL_INTERFACE:include>)

add_definitions("-DIMGUI_DISABLE_OBSOLETE_FUNCTIONS=1")

if (WIN32)
    add_definitions("-DIMGUI_IMPL_API=extern \"C\" __declspec\(dllexport\)")
else(WIN32)
    add_definitions("-DIMGUI_IMPL_API=extern \"C\" ")
endif(WIN32)

set_property(TARGET imgui-cpp APPEND PROPERTY
    PUBLIC_HEADER ${CMAKE_CURRENT_SOURCE_DIR}/imgui/imgui.h
                  ${CMAKE_CURRENT_SOURCE_DIR}/imgui/imgui_internal.h
                  ${CMAKE_CURRENT_SOURCE_DIR}/imgui/imconfig.h
                  ${CMAKE_CURRENT_SOURCE_DIR}/imgui/imstb_rectpack.h
                  ${CMAKE_CURRENT_SOURCE_DIR}/imgui/imstb_textedit.h
                  ${CMAKE_CURRENT_SOURCE_DIR}/imgui/imstb_truetype.h
                  )

install(TARGETS imgui-cpp
        EXPORT imgui-cpp-targets
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
        PUBLIC_HEADER DESTINATION include)

install(EXPORT imgui-cpp-targets
        FILE imgui-cpp-config.cmake
        DESTINATION lib/cmake/imgui-cpp)

add_library(cimgui SHARED cimgui.cpp)
target_include_directories(cimgui PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
set_target_properties(cimgui PROPERTIES PUBLIC_HEADER cimgui.h)
target_link_libraries(cimgui imgui-cpp)

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

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/compile_commands.json DESTINATION share)
