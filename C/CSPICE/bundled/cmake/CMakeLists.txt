cmake_minimum_required(VERSION 2.8.1)

project(cspice C)
enable_language(C CXX)

include(cmake/src.cmake)
if(WIN32)
  include(GenerateExportHeader)
endif()
include(GNUInstallDirs)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O2 -DNON_UNIX_STDIO")

add_library(cspice SHARED ${SRCS})
if(WIN32)
  GENERATE_EXPORT_HEADER(cspice
             BASE_NAME cspice
             EXPORT_MACRO_NAME cspice_EXPORT
             EXPORT_FILE_NAME cspice_Export.h
             STATIC_DEFINE cspice_BUILT_AS_STATIC)
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DMSDOS")
endif()
target_link_libraries(cspice m)

if(CMAKE_VERSION VERSION_GREATER 2.8.12)
    set_target_properties(cspice PROPERTIES MACOSX_RPATH ON)
endif()

INSTALL(
  TARGETS cspice
  ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
  LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
  RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
)
