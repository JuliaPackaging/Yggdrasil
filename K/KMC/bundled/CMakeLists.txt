# cmake ../ -DZLIB_LIBRARY=$libdir -DZLIB_INCLUDE_DIR=$includedir -DBZIP2_LIBRARY=$libdir -DBZIP2_INCLUDE_DIR=$includedir -DCMAKE_LIBRARY_PATH=${libdir}

cmake_minimum_required(VERSION 3.10)

project(KMC)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(ZLIB)
find_package(BZip2)

include_directories(kmc_core)
include_directories(kmc_CLI)
include_directories(kmc_dump)
include_directories(kmc_sample)
include_directories(kmc_CLI)

link_directories(kmc_core)
link_directories(kmc_CLI)
link_directories(kmc_dump)
link_directories(kmc_sample)
link_directories(kmc_CLI)

# target_link_libraries(GzipTest ZLIB::ZLIB)

# add_executable(kmc_dump kmc_dump/kmc_dump.cpp)
add_executable(kmer_tools kmc_tools/kmc_tools.cpp)
# add_executable(kmc kmc_CLI/kmc.cpp)
