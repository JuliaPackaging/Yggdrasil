cmake_minimum_required(VERSION 3.0)
project(game)
set(CMAKE_C_STANDARD 11)
if (CMAKE_SYSTEM_NAME STREQUAL Emscripten)
    set(CMAKE_EXECUTABLE_SUFFIX ".html")
endif()
option(USE_METAL "Enable/disable Metal" OFF)
# Linux -pthread shenanigans
if (CMAKE_SYSTEM_NAME STREQUAL Linux)
    set(THREADS_PREFER_PTHREAD_FLAG ON)
    find_package(Threads REQUIRED)
endif()
#=== LIBRARY: sokol
# add headers to the the file list because they are useful to have in IDEs
set(SOKOL_HEADERS
    sokol_gfx.h
    sokol_app.h
    sokol_audio.h
    sokol_time.h
    sokol_glue.h
    sokol_log.h
    sokol_args.h
    sokol_fetch.h
    )
add_library(sokol SHARED sokol.c ${SOKOL_HEADERS})
if(CMAKE_SYSTEM_NAME STREQUAL Darwin)
    set(exe_type MACOSX_BUNDLE)    
    # compile sokol.c as Objective-C
    target_compile_options(sokol PRIVATE -x objective-c)
    if(USE_METAL)
        target_link_libraries(sokol "-framework QuartzCore" "-framework Cocoa" "-framework MetalKit" "-framework Metal" "-framework AudioToolbox")
    else()
        target_link_libraries(sokol "-framework OpenGLES" "-framework GLKit")
    endif()
else()
    if (CMAKE_SYSTEM_NAME STREQUAL Linux)
        target_link_libraries(sokol INTERFACE X11 Xi Xcursor GL asound dl m)
        target_link_libraries(sokol PUBLIC Threads::Threads)
    endif()
    if(CMAKE_SYSTEM_NAME STREQUAL Windows)
        set(exe_type WIN32)
    endif()
endif()
target_include_directories(sokol INTERFACE sokol)
