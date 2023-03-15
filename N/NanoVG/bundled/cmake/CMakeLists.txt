cmake_minimum_required(VERSION 3.12.0)

project(nanovg)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
add_compile_options(-I$ENV{includedir} -Wall -Wextra)

# =============================================================== #
# =========================== NanoVG ============================ #
# =============================================================== #

add_library(nanovg SHARED ./src/nanovg.c)

set_property(TARGET nanovg APPEND PROPERTY 
    PUBLIC_HEADER ${CMAKE_CURRENT_SOURCE_DIR}/src/nanovg.h
                  ${CMAKE_CURRENT_SOURCE_DIR}/src/nanovg_gl.h
                  ${CMAKE_CURRENT_SOURCE_DIR}/src/nanovg_gl_utils.h)

target_include_directories(nanovg PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    $<INSTALL_INTERFACE:include>)

if(WIN32)
    target_link_libraries(nanovg $ENV{bindir}/glew32.dll)
    target_link_libraries(nanovg "opengl32.lib")
else()
    add_compile_options(-L$ENV{libdir})
    target_link_libraries(nanovg GLEW)
    target_link_libraries(nanovg "-lGL")
endif()

link_libraries(nanovg)

install(TARGETS nanovg
    EXPORT nanovg-targets
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    PUBLIC_HEADER DESTINATION include
)

install(EXPORT nanovg-targets
    FILE nanovg-config.cmake
    DESTINATION lib/cmake/nanovg)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/compile_commands.json DESTINATION share)

# =============================================================== #
# =========================== NanoVG GL2 ======================== #
# =============================================================== #

add_library(nanovggl2 SHARED ./src/nanovg_gl2.c)

target_include_directories(nanovggl2 PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    $<INSTALL_INTERFACE:include>)

if(WIN32)
    target_link_libraries(nanovggl2 $ENV{bindir}/glew32.dll)
    target_link_libraries(nanovggl2 "opengl32.lib")
else()
    add_compile_options(-L$ENV{libdir})
    target_link_libraries(nanovg GLEW)
    target_link_libraries(nanovggl2 "-lGL")
endif()

link_libraries(nanovggl2)

install(TARGETS nanovggl2
    EXPORT nanovggl2-targets
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    PUBLIC_HEADER DESTINATION include
)

install(EXPORT nanovggl2-targets
    FILE nanovggl2-config.cmake
    DESTINATION lib/cmake/nanovggl2)

# =============================================================== #
# =========================== NanoVG GL3 ======================== #
# =============================================================== #

add_library(nanovggl3 SHARED ./src/nanovg_gl3.c)

target_include_directories(nanovggl3 PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    $<INSTALL_INTERFACE:include>)

if(WIN32)
    target_link_libraries(nanovggl3 $ENV{bindir}/glew32.dll)
    target_link_libraries(nanovggl3 "opengl32.lib")
else()
    add_compile_options(-L$ENV{libdir})
    target_link_libraries(nanovg GLEW)
    target_link_libraries(nanovggl3 "-lGL")
endif()

link_libraries(nanovggl3)

install(TARGETS nanovggl3
    EXPORT nanovggl3-targets
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    PUBLIC_HEADER DESTINATION include
)

install(EXPORT nanovggl3-targets
    FILE nanovggl3-config.cmake
    DESTINATION lib/cmake/nanovggl3)

# =============================================================== #
# ========================= NanoVG GLES2 ======================== #
# =============================================================== #

add_library(nanovggles2 SHARED ./src/nanovg_gles2.c)

target_include_directories(nanovggles2 PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    $<INSTALL_INTERFACE:include>)

if(WIN32)
    target_link_libraries(nanovggles2 $ENV{bindir}/glew32.dll)
    target_link_libraries(nanovggles2 "opengl32.lib")
else()
    add_compile_options(-L$ENV{libdir})
    target_link_libraries(nanovg GLEW)
    target_link_libraries(nanovggles2 "-lGL")
endif()

link_libraries(nanovggles2)

install(TARGETS nanovggles2
    EXPORT nanovggles2-targets
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    PUBLIC_HEADER DESTINATION include
)

install(EXPORT nanovggles2-targets
    FILE nanovggles2-config.cmake
    DESTINATION lib/cmake/nanovggles2)

# =============================================================== #
# ========================= NanoVG GLES3 ======================== #
# =============================================================== #

add_library(nanovggles3 SHARED ./src/nanovg_gles3.c)

target_include_directories(nanovggles3 PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    $<INSTALL_INTERFACE:include>)

if(WIN32)
    target_link_libraries(nanovggles3 $ENV{bindir}/glew32.dll)
    target_link_libraries(nanovggles3 "opengl32.lib")
else()
    add_compile_options(-L$ENV{libdir})
    target_link_libraries(nanovg GLEW)
    target_link_libraries(nanovggles3 "-lGL")
endif()

link_libraries(nanovggles3)

install(TARGETS nanovggles3
    EXPORT nanovggles3-targets
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    PUBLIC_HEADER DESTINATION include
)

install(EXPORT nanovggles3-targets
    FILE nanovggles3-config.cmake
    DESTINATION lib/cmake/nanovggles3)
