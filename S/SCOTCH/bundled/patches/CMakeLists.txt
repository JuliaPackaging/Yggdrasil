## Copyright 2014-2016,2021-2023 IPB, Universite de Bordeaux, INRIA & CNRS
##
## This file is part of the Scotch software package for static mapping,
## graph partitioning and sparse matrix ordering.
##
## This software is governed by the CeCILL-C license under French law
## and abiding by the rules of distribution of free software. You can
## use, modify and/or redistribute the software under the terms of the
## CeCILL-C license as circulated by CEA, CNRS and INRIA at the following
## URL: "http://www.cecill.info".
##
## As a counterpart to the access to the source code and rights to copy,
## modify and redistribute granted by the license, users are provided
## only with a limited warranty and the software's author, the holder of
## the economic rights, and the successive licensors have only limited
## liability.
##
## In this respect, the user's attention is drawn to the risks associated
## with loading, using, modifying and/or developing or reproducing the
## software by the user in light of its specific status of free software,
## that may mean that it is complicated to manipulate, and that also
## therefore means that it is reserved for developers and experienced
## professionals having in-depth computer knowledge. Users are therefore
## encouraged to load and test the software's suitability as regards
## their requirements in conditions enabling the security of their
## systems and/or data to be ensured and, more generally, to use and
## operate it in the same conditions as regards security.
##
## The fact that you are presently reading this means that you have had
## knowledge of the CeCILL-C license and that you accept its terms.
##
############################################################
##                                                        ##
##   AUTHORS    : Marc FUENTES                            ##
##                Florent PRUVOST                         ##
##                                                        ##
##   FUNCTION   : Top-level CMake configuration file      ##
##                                                        ##
##   DATES      : # Version 7.0  : from : 18 jan 2022     ##
##                                 to     01 nov 2023     ##
##                                                        ##
############################################################

cmake_minimum_required(VERSION 3.10)
project(SCOTCH LANGUAGES C Fortran)

# Add module directory
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/Modules)

set(SCOTCH_VERSION 7)
set(SCOTCH_RELEASE 0)
set(SCOTCH_PATCHLEVEL 5)
set(SCOTCH_CODENAME "Sankara")

add_definitions(-DSCOTCH_VERSION_NUM=${SCOTCH_VERSION}
  -DSCOTCH_RELEASE_NUM=${SCOTCH_RELEASE}
  -DSCOTCH_PATCHLEVEL_NUM=${SCOTCH_PATCHLEVEL})

set(SCOTCH_VERSION_LONG "${SCOTCH_VERSION}.${SCOTCH_RELEASE}.${SCOTCH_PATCHLEVEL}")

# Set integer size: by default, use compiler int size
set(INTSIZE "" CACHE STRING "Integer size: empty string stands for C compiler int type size")

# Thread support
option(THREADS "Use multi-threading in Scotch and PT-Scotch" ON)

# Use MPI with threads
option(MPI_THREAD_MULTIPLE "Use multi-threading with MPI in PT-Scotch" ON)

# Build Dummysizes
option(BUILD_DUMMYSIZES "Build Dummysizes" ON)

# Build PT-Scotch
option(BUILD_PTSCOTCH "Build PT-Scotch" ON)

# Build libESMUMPS
option(BUILD_LIBESMUMPS "Build EsMUMPS library" ON)

# Build libScotchMeTiS
option(BUILD_LIBSCOTCHMETIS "Build ScotchMeTiS library" ON)

# Prefix Scotch version of MeTiS routines
option(SCOTCH_METIS_PREFIX "Prefix Scotch version of MeTiS routines" OFF)

# Install our MeTiS header stubs
option(INSTALL_METIS_HEADERS "Install libScotchMeTiS headers in destination directory" ON)

# Compression format options
option(USE_ZLIB "Use ZLIB compression format if found" ON)
option(USE_LZMA "Use LZMA compression format if found" ON)
option(USE_BZ2 "Use BZ2 compression format if found" ON)

# Set fPIC flag when building shared libraries
set(CMAKE_POSITION_INDEPENDENT_CODE ${BUILD_SHARED_LIBS})

# Allow for testing
option(ENABLE_TESTS "Enable testing" ON)
if(ENABLE_TESTS)
  enable_testing()
endif(ENABLE_TESTS)

# use GNU standard for file hierarchy installation system
include(GNUInstallDirs)

add_subdirectory(src)

# Install man pages
set(scotch_man_pages
acpl.1
amk_ccc.1
amk_grf.1
atst.1
gbase.1
gcv.1
gdump.1
gmap.1
gmk_hy.1
gmk_m2.1
gmk_msh.1
gmtst.1
gord.1
gotst.1
gout.1
gtst.1
mcv.1
mmk_m2.1
mord.1
mtst.1
)
foreach(f IN LISTS scotch_man_pages)
  install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/man/man1/${f}
    DESTINATION ${CMAKE_INSTALL_DATADIR}/man/man1 COMPONENT scotch)
endforeach()

if (BUILD_PTSCOTCH)
  set(ptscotch_man_pages dgmap.1 dgord.1 dgscat.1 dgtst.1)
  foreach(f IN LISTS ptscotch_man_pages)
    install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/man/man1/${f}
      DESTINATION ${CMAKE_INSTALL_DATADIR}/man/man1 COMPONENT ptscotch)
  endforeach()
endif(BUILD_PTSCOTCH)
