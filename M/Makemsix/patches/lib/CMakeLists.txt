# MSIX\lib
# Copyright (C) 2017 Microsoft.  All rights reserved.
# See LICENSE file in the project root for full license information.
cmake_minimum_required(VERSION 3.21.7)

add_custom_target(LIBS)

# Use system zlib but create a zlibstatic target that points to our shared library
find_package(ZLIB REQUIRED)
if(ZLIB_FOUND AND NOT TARGET zlibstatic)
    add_library(zlibstatic INTERFACE)
    target_link_libraries(zlibstatic INTERFACE ZLIB::ZLIB)
endif()

# Use system XercesC
if(XML_PARSER MATCHES xerces)
    message(STATUS "Using system Xerces-C" )
    find_package(XercesC)
    
    # If XercesC wasn't found by find_package, set it up manually
    if(NOT XercesC_FOUND)
        message(STATUS "XercesC not found by find_package, setting manually")
        set(XercesC_INCLUDE_DIR "${CMAKE_INSTALL_PREFIX}/include")
        set(XercesC_LIBRARY "${CMAKE_INSTALL_PREFIX}/lib/libxerces-c.dylib")
        set(XercesC_VERSION "3.2.4")
        
        include(FindPackageHandleStandardArgs)
        find_package_handle_standard_args(XercesC
            REQUIRED_VARS XercesC_LIBRARY XercesC_INCLUDE_DIR
            VERSION_VAR XercesC_VERSION)
            
        if(NOT TARGET XercesC::XercesC)
            add_library(XercesC::XercesC UNKNOWN IMPORTED)
            set_target_properties(XercesC::XercesC PROPERTIES
                IMPORTED_LOCATION "${XercesC_LIBRARY}"
                INTERFACE_INCLUDE_DIRECTORIES "${XercesC_INCLUDE_DIR}")
        endif()
        
        set(XercesC_FOUND TRUE)
    endif()
    
    message(STATUS "XercesC_INCLUDE_DIR: ${XercesC_INCLUDE_DIR}")
    message(STATUS "XercesC_LIBRARY: ${XercesC_LIBRARY}")
endif()

# OpenSSL (use vendored version)
if(CRYPTO_LIB MATCHES openssl)
    message(STATUS "-----------------------------")
    message(STATUS "OpenSLL configuration summary")
    message(STATUS "-----------------------------")

    set(OpenSSL_SOURCE_PATH  "${CMAKE_CURRENT_SOURCE_DIR}/openssl" )
    set(OpenSLL_BINARY_PATH  "${CMAKE_CURRENT_BINARY_DIR}" )
    set(OpenSLL_INCLUDE_PATH "${CMAKE_CURRENT_BINARY_DIR}" )

    set(OpenSLL_VERSION "1.1.1")

    set(OpenSSL_COMPILER_DEFINES OPENSSL_NO_ASM)
    # we include which means you need to use "OpenSSL_X_PATH" for your paths.
    include( crypto )
    set(OpenSSL_FOUND ON CACHE BOOL "OpenSSL ready for use" FORCE)

    message(STATUS "OpenSLL_VERSION      '${OpenSLL_VERSION}'" )
    message(STATUS "OpenSSL_SOURCE_PATH  '${OpenSSL_SOURCE_PATH}'" )
    message(STATUS "OpenSLL_BINARY_PATH  '${OpenSLL_BINARY_PATH}'" )
    message(STATUS "OpenSLL_INCLUDE_PATH '${OpenSLL_INCLUDE_PATH}'" )
endif()
