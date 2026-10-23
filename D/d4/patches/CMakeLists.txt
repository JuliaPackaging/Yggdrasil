cmake_minimum_required(VERSION 3.10)
project(D4 VERSION 2.0.0)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

find_package(Boost REQUIRED COMPONENTS program_options)
find_package(TBB REQUIRED)
find_package(ZLIB REQUIRED)
find_path(GMP_INCLUDE_DIR gmp.h)
find_library(GMP_LIBRARY NAMES gmp)
find_library(GMPXX_LIBRARY NAMES gmpxx)

include_directories(
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/3rdParty/bipe/src
    ${CMAKE_SOURCE_DIR}/3rdParty/glucose-3.0
    ${CMAKE_SOURCE_DIR}/3rdParty/flowCutter/src
    ${GMP_INCLUDE_DIR}
)

file(GLOB_RECURSE SRC_FILES "src/*.cpp" "src/*.cc")
file(GLOB_RECURSE BIPE_FILES "3rdParty/bipe/src/*.cpp" "3rdParty/bipe/src/*.cc")
file(GLOB_RECURSE FLOW_FILES "3rdParty/flowCutter/src/*.cpp" "3rdParty/flowCutter/src/*.cc")

set(SOURCES 
    ${SRC_FILES} 
    ${BIPE_FILES} 
    ${FLOW_FILES} 
    "3rdParty/glucose-3.0/core/Solver.cc"
)

list(FILTER SOURCES EXCLUDE REGEX "PartitionerPatoh")
list(FILTER SOURCES EXCLUDE REGEX "PartitionerKahypar")

add_library(d4 SHARED ${SOURCES})
target_compile_definitions(d4 PRIVATE NOMAIN)
target_link_libraries(d4 
    ${GMPXX_LIBRARY} 
    ${GMP_LIBRARY} 
    ${Boost_LIBRARIES} 
    TBB::tbb 
    ZLIB::ZLIB
)

add_executable(d4-bin 
    demo/compiler/src/Main.cpp 
    demo/compiler/src/CompilerDemo.cpp 
    demo/compiler/src/ParseOption.cpp
)
set_target_properties(d4-bin PROPERTIES OUTPUT_NAME d4)
target_link_libraries(d4-bin d4 ${Boost_LIBRARIES} TBB::tbb)

install(TARGETS d4 d4-bin
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

install(DIRECTORY src/ DESTINATION include/d4 FILES_MATCHING PATTERN "*.hpp" PATTERN "*.h")
