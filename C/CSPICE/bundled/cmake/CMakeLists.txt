cmake_minimum_required(VERSION 3.0.0)

project(cspice C)

if(WIN32)
  include(GenerateExportHeader)
endif()
include(GNUInstallDirs)

set(CMAKE_C_STANDARD 90)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O2 -DNON_UNIX_STDIO")
if(WIN32)
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DMSDOS")
endif()
cmake_policy(SET CMP0042 NEW)

include_directories(include)

include(cmake/cspice.cmake)
include(cmake/csupport.cmake)
include(cmake/brief.cmake)
include(cmake/chronos.cmake)
include(cmake/ckbrief.cmake)
include(cmake/commnt.cmake)
include(cmake/dskbrief.cmake)
include(cmake/dskexp.cmake)
include(cmake/frmdiff.cmake)
include(cmake/inspekt.cmake)
include(cmake/mkdsk.cmake)
include(cmake/mkspk.cmake)
include(cmake/msopck.cmake)
include(cmake/spacit.cmake)
include(cmake/spkdiff.cmake)
include(cmake/spkmerge.cmake)
include(cmake/tobin.cmake)
include(cmake/toxfr.cmake)
include(cmake/version.cmake)

INSTALL(
  TARGETS
  cspice
  csupport
  brief
  chronos
  ckbrief
  commnt
  dskbrief
  dskexp
  frmdiff
  inspekt
  mkdsk
  mkspk
  msopck
  spacit
  spkdiff
  spkmerge
  tobin
  toxfr
  version
  ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
  LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
  RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
  PUBLIC_HEADER DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
)
