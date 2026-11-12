# Patch to use system dependencies instead of vendored ones.

add_custom_target(LIBS)

# Use system zlib but create a zlibstatic target that points to our shared library
find_package(ZLIB REQUIRED)
if(ZLIB_FOUND AND NOT TARGET zlibstatic)
    add_library(zlibstatic INTERFACE)
    target_link_libraries(zlibstatic INTERFACE ZLIB::ZLIB)
endif()

# Use system XercesC
find_package(XercesC)

# OpenSSL configuration
if(CRYPTO_LIB MATCHES openssl)
    message(STATUS "-----------------------------")
    message(STATUS "OpenSSL configuration summary")
    message(STATUS "-----------------------------")

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
    
    # Add include directory
    include_directories(${OPENSSL_INCLUDE_DIR})
    
    # Display configuration
    message(STATUS "OpenSSL include dir: ${OPENSSL_INCLUDE_DIR}")
    message(STATUS "OpenSSL SSL library: ${OPENSSL_SSL_LIBRARY}")
    message(STATUS "OpenSSL Crypto library: ${OPENSSL_CRYPTO_LIBRARY}")
    message(STATUS "-----------------------------")
endif()
