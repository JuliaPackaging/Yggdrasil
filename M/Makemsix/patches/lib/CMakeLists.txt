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



# OpenSSL configuration
if(CRYPTO_LIB MATCHES openssl)
    message(STATUS "-----------------------------")
    message(STATUS "OpenSSL configuration summary")
    message(STATUS "-----------------------------")

    # Use environment variables for OpenSSL
    set(OPENSSL_CRYPTO_LIBRARY $ENV{OPENSSL_CRYPTO_LIBRARY})
    set(OPENSSL_SSL_LIBRARY $ENV{OPENSSL_SSL_LIBRARY})
    set(OPENSSL_INCLUDE_DIR $ENV{OPENSSL_INCLUDE_DIR})
    
    # Set found flags as cache variables
    set(OPENSSL_FOUND TRUE CACHE BOOL "OpenSSL found" FORCE)
    set(OpenSSL_FOUND TRUE CACHE BOOL "OpenSSL found" FORCE)
    
    # Create imported targets
    add_library(OpenSSL::Crypto UNKNOWN IMPORTED)
    set_target_properties(OpenSSL::Crypto PROPERTIES
        IMPORTED_LOCATION "${OPENSSL_CRYPTO_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${OPENSSL_INCLUDE_DIR}")
    
    add_library(OpenSSL::SSL UNKNOWN IMPORTED)
    set_target_properties(OpenSSL::SSL PROPERTIES
        IMPORTED_LOCATION "${OPENSSL_SSL_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${OPENSSL_INCLUDE_DIR}"
        INTERFACE_LINK_LIBRARIES OpenSSL::Crypto)
    
    # Set compatibility variables
    set(OPENSSL_LIBRARIES "${OPENSSL_SSL_LIBRARY};${OPENSSL_CRYPTO_LIBRARY}" CACHE STRING "OpenSSL libraries" FORCE)
    
    # Add include directory
    include_directories(${OPENSSL_INCLUDE_DIR})
    
    # Display configuration
    message(STATUS "OpenSSL include dir: ${OPENSSL_INCLUDE_DIR}")
    message(STATUS "OpenSSL SSL library: ${OPENSSL_SSL_LIBRARY}")
    message(STATUS "OpenSSL Crypto library: ${OPENSSL_CRYPTO_LIBRARY}")
    message(STATUS "-----------------------------")
endif()

