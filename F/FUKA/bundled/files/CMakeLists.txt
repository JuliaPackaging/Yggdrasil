# Builds what upstream's build_release/CMakeLists.txt and the
# codes/FUKA/*/CMakeLists.txt build, as a shared library with installed
# solvers, plus our C interface in capi/. Upstream's build finds its sources
# through $HOME_KADATH, copies src_par/do_newton.cpp into the source tree,
# builds only a static library, sets CMAKE_CXX_COMPILER to the MPI wrapper
# and installs nothing.

cmake_minimum_required(VERSION 3.12)
project(FUKA C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
# Upstream's release build keeps assertions enabled.
set(CMAKE_CXX_FLAGS_RELEASE "-O3")

find_package(MPI REQUIRED COMPONENTS C)

set(LAPACK_LIBRARIES "" CACHE STRING "BLAS and LAPACK libraries")

file(GLOB_RECURSE KADATH_SOURCES ${CMAKE_SOURCE_DIR}/src/*.cpp)
add_library(kadath SHARED ${KADATH_SOURCES} ${CMAKE_SOURCE_DIR}/src_par/do_newton.cpp)
target_include_directories(kadath PUBLIC
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/include/Kadath_point_h)
# Only the MPI C API is used; don't pull in the deprecated C++ bindings.
target_compile_definitions(kadath PUBLIC MPICH_SKIP_MPICXX OMPI_SKIP_MPICXX)
target_link_libraries(kadath PUBLIC
    MPI::MPI_C scalapack32 ${LAPACK_LIBRARIES} fftw3 gsl gslcblas)
install(TARGETS kadath
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib)

# C interface to the initial data exporters, for calling from Julia
add_library(fuka SHARED capi/fuka.cpp)
target_link_libraries(fuka PRIVATE kadath)
install(TARGETS fuka
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib)
install(FILES capi/fuka.h DESTINATION include)

foreach(code BBH BH BHNS BNS BNS_headon NS NS_DIFFROT NS_isotropic)
    file(GLOB programs ${CMAKE_SOURCE_DIR}/codes/FUKA/${code}/src/*.cpp)
    foreach(source ${programs})
        get_filename_component(program ${source} NAME_WE)
        # Every code has programs called `solve` and `reader`.
        string(TOLOWER "fuka_${code}_${program}" exe)
        add_executable(${exe} ${source})
        target_link_libraries(${exe} kadath)
        install(TARGETS ${exe} RUNTIME DESTINATION bin)
    endforeach()
endforeach()

install(DIRECTORY include/ DESTINATION include/kadath)
install(DIRECTORY eos/ DESTINATION share/fuka/eos)
