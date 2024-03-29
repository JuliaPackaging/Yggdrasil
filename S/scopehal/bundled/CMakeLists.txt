cmake_minimum_required(VERSION 3.14)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
project(glscopeclient)

include(CTest)

# Configuration settings
set(BUILD_DOCS CACHE BOOL "Build the documentation")
set(ANALYZE CACHE BOOL "Run static analysis on the code, requires cppcheck and clang-analyzer to be installed")

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON) # error if compiler doesn't support c++11
set(CMAKE_CXX_EXTENSIONS OFF) # use c++11 instead of gnu++11

# Compiler flags
set(WARNINGS "-Wall -Wextra -Wuninitialized ")
set(WARNINGS "${WARNINGS} -Wshadow -Wpedantic -Wcast-align -Wwrite-strings")
set(WARNINGS "${WARNINGS} -Wmissing-declarations -Wvla")

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  set(WARNINGS "${WARNINGS} -Wunsafe-loop-optimizations")
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  set(WARNINGS "${WARNINGS} -Wno-gnu-zero-variadic-macro-arguments")
endif()

set(CMAKE_CXX_FLAGS "-g ${WARNINGS}")
set(CMAKE_CXX_FLAGS_RELEASE "-O3")

# clang doesn't properly use the attributes and so requires avx to build
# should get fixed in #475
if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mavx")
endif()

if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE "Release")
endif(NOT CMAKE_BUILD_TYPE)

# seems like asan doesn't play well with OpenCL so don't enable by default in debug modes
# (causes clGetPlatformIDs to return -1001)
if(SANITIZE)
	set(CMAKE_CXX_FLAGS_DEBUG "-O0 -fsanitize=address -D_DEBUG")
else()
	set(CMAKE_CXX_FLAGS_DEBUG "-O0 -D_DEBUG")
endif()

if(WIN32)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_USE_MATH_DEFINES -D_POSIX_THREAD_SAFE_FUNCTIONS")
endif()

# Package detection
find_package(PkgConfig)
# pkg_check_modules(GTKMM REQUIRED gtkmm-3.0)
# pkg_check_modules(SIGCXX REQUIRED sigc++-2.0)
find_package(FFTS)
find_package(OpenCL)
include(FindOpenMP)

if(NOT WIN32)
	include(GNUInstallDirs)
endif()

# Configure and enable OpenMP
if(OpenMP_CXX_FOUND)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
endif()

pkg_search_module(CLFFT clFFT>=2.0)

# Static analysis
if(ANALYZE)
	find_program(CPPCHECK_PATH cppcheck DOC "Path to cppcheck when ANALYZE is enabled")
	if(CPPCHECK_PATH)
		execute_process(COMMAND ${CPPCHECK_PATH} "--version" OUTPUT_VARIABLE CPPCHECK_VER_STR ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)
		string(REPLACE "Cppcheck " "" CPPCHECK_VERSION ${CPPCHECK_VER_STR})
		if(CPPCHECK_VERSION VERSION_GREATER_EQUAL "2")
			set(CMAKE_CXX_CPPCHECK "${CPPCHECK_PATH};-DFT_USE_AUTOCONF_SIZEOF_TYPES;-D__GNUC__;--enable=warning,performance,portability;--suppress=*:*sigc*;--suppress=*:*glibmm*;--suppress=*:*gtkmm*;--inline-suppr;-q;--std=c++11")
			message(STATUS "Found CPPCheck: ${CPPCHECK_PATH} (found version \"${CPPCHECK_VERSION}\")")
		else()
			message(STATUS "Found CPPCheck: ${CPPCHECK_PATH} but ignored it as it was ${CPPCHECK_VERSION} < 2")
		endif()
	else()
		message(STATUS "CPPCheck not found")
	endif()
	# The actual clang-analyzer compiler wrapper doesn't get installed on $PATH, only scan-build which is useless to us
	find_program(CLANGANALYZER_SCANBUILD_PATH scan-build DOC "Path to clang-analyzer's scan-build tool, used as a hint to find the rest of the clang-analyzer")
	get_filename_component(CLANGANALYZER_SCANBUILD_BIN ${CLANGANALYZER_SCANBUILD_PATH} REALPATH)
	get_filename_component(CLANGANALYZER_BIN_PATH ${CLANGANALYZER_SCANBUILD_BIN} DIRECTORY)
	find_program(CLANGANALYZER_CXXANALYZER_PATH "c++-analyzer" HINTS "${CLANGANALYZER_BIN_PATH}/../libexec" DOC "Path to clang-analyzer's c++-analyzer")
	if(CLANGANALYZER_CXXANALYZER_PATH)
		set(CMAKE_CXX_COMPILER_LAUNCHER "${CLANGANALYZER_CXXANALYZER_PATH}")
		message(STATUS "Found clang-analyzer: ${CLANGANALYZER_CXXANALYZER_PATH}")
	else()
		message(STATUS "clang-analyzer not found")
	endif()
endif()

# Main project code
add_subdirectory("${PROJECT_SOURCE_DIR}/scopehal/scopehal")
add_subdirectory("${PROJECT_SOURCE_DIR}/scopehal/log")
add_subdirectory("${PROJECT_SOURCE_DIR}/scopehal/xptools")

# Make sure all of our shared libraries are built relocatable
set_property(TARGET scopehal PROPERTY POSITION_INDEPENDENT_CODE ON)
set_property(TARGET log PROPERTY POSITION_INDEPENDENT_CODE ON)
set_property(TARGET xptools PROPERTY POSITION_INDEPENDENT_CODE ON)

find_package(JlCxx)
get_target_property(JlCxx_location JlCxx::cxxwrap_julia LOCATION)
get_filename_component(JlCxx_location ${JlCxx_location} DIRECTORY)
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib;${JlCxx_location}")

message(STATUS "Found JlCxx at ${JlCxx_location}")

add_library(scopehalwrapper SHARED scopehalwrapper.cpp)

target_link_libraries(scopehalwrapper
  JlCxx::cxxwrap_julia
  scopehal
)

install(TARGETS scopehalwrapper LIBRARY)