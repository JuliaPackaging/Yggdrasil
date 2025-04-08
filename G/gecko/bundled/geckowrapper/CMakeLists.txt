# Adapted from https://github.com/JuliaPackaging/Yggdrasil/blob/50502fe77174eff96d303bb5bd9ced6809262248/S/SDPA/bundled/sdpawrap/CMakeLists.txt#L1-L43
project(GeckoWrapper)

cmake_minimum_required(VERSION 2.8.12)
#set(CMAKE_MACOSX_RPATH 1)
set(CMAKE_MACOSX_RPATH 0)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

# debug
set(CMAKE_VERBOSE_MAKEFILE ON)

find_package(JlCxx)

set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib;${Julia_LIBRARY_DIR}")

include_directories(${GECKO_DIR})
include_directories(${Julia_INCLUDE_DIRS})
include_directories(${CMAKE_SOURCE_DIR}/include)
include_directories(${INTERFACE_INCLUDE_DIRECTORIES})

add_library(geckowrapper SHARED geckowrapper.cxx)
target_link_libraries(geckowrapper JlCxx::cxxwrap_julia JlCxx::cxxwrap_julia_stl ${GECKO_LIBRARY})

install(TARGETS
    geckowrapper
LIBRARY DESTINATION lib${LIBDIR_SUFFIX}
ARCHIVE DESTINATION lib${LIBDIR_SUFFIX}
RUNTIME DESTINATION lib${LIBDIR_SUFFIX}
INCLUDES DESTINATION include)
