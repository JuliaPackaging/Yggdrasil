project(SDPAWrap)

cmake_minimum_required(VERSION 2.8.12)
#set(CMAKE_MACOSX_RPATH 1)
set(CMAKE_MACOSX_RPATH 0)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
add_definitions(-DJULIA_ENABLE_THREADING)


# debug
set(CMAKE_VERBOSE_MAKEFILE ON)

find_package(JlCxx)

set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib;${Julia_LIBRARY_DIR}")

# See https://github.com/blegat/SDPA.jl/pull/11#issuecomment-422154825
#get_target_property(JlCxx_location JlCxx::cxxwrap_julia LOCATION)
#get_filename_component(JlCxx_location ${JlCxx_location} DIRECTORY)
#set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib;${JlCxx_location}")

include_directories(${SDPA_DIR})
include_directories(${MUMPS_INCLUDE_DIR})
include_directories(${Julia_INCLUDE_DIRS})
include_directories(${CMAKE_SOURCE_DIR}/include)
include_directories(${INTERFACE_INCLUDE_DIRECTORIES})


add_library(sdpawrap SHARED sdpawrap.cpp)
# ${PORD_LIB}: PORD_LIB does not seem usefull
#target_include_directories(sdpawrap PRIVATE ${Julia_INCLUDE_DIRS})
target_link_libraries(sdpawrap JlCxx::cxxwrap_julia ${SDPA_LIBRARY})
#target_link_libraries(sdpawrap ${JLCXX_TARGET})

#get_property(JULIA_LIBRARY TARGET JlCxx::cxxwrap_julia PROPERTY INTERFACE_LINK_LIBRARIES)
#get_property(JULIA_INCLUDE_DIRS TARGET JlCxx::cxxwrap_julia PROPERTY INTERFACE_INCLUDE_DIRECTORIES)

install(TARGETS
    sdpawrap
LIBRARY DESTINATION lib${LIBDIR_SUFFIX}
ARCHIVE DESTINATION lib${LIBDIR_SUFFIX}
RUNTIME DESTINATION lib${LIBDIR_SUFFIX}
INCLUDES DESTINATION include)
