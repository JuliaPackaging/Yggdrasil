cmake_minimum_required(VERSION 3.1)
project(awscrt C)
set(BUILD_SHARED_LIBS ON)

if (DEFINED CMAKE_PREFIX_PATH)
    file(TO_CMAKE_PATH "${CMAKE_PREFIX_PATH}" CMAKE_PREFIX_PATH)
endif()

if (DEFINED CMAKE_INSTALL_PREFIX)
    file(TO_CMAKE_PATH "${CMAKE_INSTALL_PREFIX}" CMAKE_INSTALL_PREFIX)
endif()

if (UNIX AND NOT APPLE)
    include(GNUInstallDirs)
elseif(NOT DEFINED CMAKE_INSTALL_LIBDIR)
    set(CMAKE_INSTALL_LIBDIR "lib")
endif()

# This is required in order to append /lib/cmake to each element in CMAKE_PREFIX_PATH
set(AWS_MODULE_DIR "/${CMAKE_INSTALL_LIBDIR}/cmake")
string(REPLACE ";" "${AWS_MODULE_DIR};" AWS_MODULE_PATH "${CMAKE_PREFIX_PATH}${AWS_MODULE_DIR}")
# Append that generated list to the module search path
list(APPEND CMAKE_MODULE_PATH ${AWS_MODULE_PATH})

include(AwsCFlags)
include(AwsCheckHeaders)
include(AwsSharedLibSetup)
include(AwsSanitizers)
include(CheckCCompilerFlag)
include(AwsFindPackage)

add_library(${PROJECT_NAME} empty.c)

set(BUILD_SHARED_LIBS OFF) # Set up static libs for this part because this is required to grab static objects
# Include the packages that AWS has marked as being part of the CRT bindings
aws_use_package(aws-c-cal)
aws_use_package(aws-c-http)
aws_use_package(aws-c-mqtt)
aws_use_package(aws-checksums)
aws_use_package(aws-c-event-stream)
aws_use_package(aws-c-auth)
aws_use_package(aws-c-s3)
set(BUILD_SHARED_LIBS ON)

if(APPLE)
    target_link_libraries(${PROJECT_NAME} "-Wl,-all_load" ${DEP_AWS_LIBS})
else()
    target_link_libraries(${PROJECT_NAME} "-Wl,--whole-archive" ${DEP_AWS_LIBS} "-Wl,--no-whole-archive")
endif()

aws_prepare_shared_lib_exports(${PROJECT_NAME})

set(TARGET_DIR "shared")

install(EXPORT "${PROJECT_NAME}-targets"
        DESTINATION "${LIBRARY_DIRECTORY}/${PROJECT_NAME}/cmake/${TARGET_DIR}"
        NAMESPACE AWS::
        COMPONENT Development)

configure_file("cmake/${PROJECT_NAME}-config.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake"
        @ONLY)

install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake"
        DESTINATION "${LIBRARY_DIRECTORY}/${PROJECT_NAME}/cmake/"
        COMPONENT Development)
