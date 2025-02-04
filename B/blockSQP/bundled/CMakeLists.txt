cmake_minimum_required(VERSION 3.18)

# Project Information
project(blockSQP
    DESCRIPTION "Sequential quadratic programming for problems with block-diagonal Hessian matrix."
    HOMEPAGE_URL https://github.com/djanka2/blockSQP
    LANGUAGES CXX
    )

# Find dependencies: LAPACK
find_package(LAPACK REQUIRED)

# Find dependencies: qpOASES
find_path(QPOASES_PREFIX
    include/qpOASES.hpp
    DOC "qpOASES directory prefix."
    REQUIRED
    )
find_library(QPOASES_LIBRARY
    qpOASES
    REQUIRED
    )

# Add target
add_library(blockSQP SHARED
    src/blocksqp_matrix.cpp
    src/blocksqp_problemspec.cpp
    src/blocksqp_general_purpose.cpp
    src/blocksqp_glob.cpp
    src/blocksqp_hess.cpp
    src/blocksqp_iter.cpp
    src/blocksqp_main.cpp
    src/blocksqp_options.cpp
    src/blocksqp_qp.cpp
    src/blocksqp_restoration.cpp
    src/blocksqp_stats.cpp
    )
set_property(TARGET blockSQP PROPERTY PUBLIC_HEADER
    include/blocksqp_defs.hpp
    include/blocksqp_general_purpose.hpp
    include/blocksqp_iterate.hpp
    include/blocksqp_lapack.h
    include/blocksqp_matrix.hpp
    include/blocksqp_method.hpp
    include/blocksqp_options.hpp
    include/blocksqp_problemspec.hpp
    include/blocksqp_restoration.hpp
    include/blocksqp_stats.hpp
    )
target_include_directories(blockSQP PUBLIC include ${QPOASES_PREFIX}/include)
target_link_libraries(blockSQP LAPACK::LAPACK ${QPOASES_LIBRARY})
install(TARGETS blockSQP
    LIBRARY
    PUBLIC_HEADER
        DESTINATION include/blockSQP
    )


# Build wrapper library for blockSQP
message(STATUS "Current CMAKE SRC DIR ${CMAKE_CURRENT_SOURCE_DIR}")
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR})
message(STATUS "Current CMAKE MODULE PATH ${CMAKE_MODULE_PATH}")

#find_package(Julia REQUIRED)

find_package(JlCxx)
get_target_property(JlCxx_location JlCxx::cxxwrap_julia LOCATION)
get_filename_component(JlCxx_location ${JlCxx_location} DIRECTORY)
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib;${JlCxx_location}")

message(STATUS "Found JlCxx at ${JlCxx_location}")

add_library(blockSQP_wrapper SHARED src/blockSQP_julia.cpp)
add_dependencies(blockSQP_wrapper blockSQP)

target_include_directories(blockSQP_wrapper 
	PUBLIC ${blockSQP_INCLUDES})
target_link_libraries(blockSQP_wrapper blockSQP JlCxx::cxxwrap_julia)

install(TARGETS blockSQP_wrapper
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
