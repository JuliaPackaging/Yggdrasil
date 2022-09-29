cmake_minimum_required(VERSION 3.10)

project(KMC)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Threads REQUIRED)
find_package(ZLIB)
find_package(BZip2)

FILE(GLOB kmc_cli_sources
  kmc_CLI/*
)


FILE(GLOB kmc_tools_sources
  kmc_tools/*
)

FILE(GLOB kmc_api_sources
  kmc_api/*
)

FILE(GLOB kmc_dump_sources
  kmc_dump/*
)

FILE(GLOB kmc_core_sources
  kmc_core/*
)

FILE(GLOB kmc_kff_sources
  kmc_core/kff_writer.*
)

# include_directories(kmc_core)
# include_directories(kmc_CLI)
# include_directories(kmc_dump)
# include_directories(kmc_sample)
# include_directories(kmc_CLI)

# link_directories(kmc_core)
# link_directories(kmc_CLI)
# link_directories(kmc_dump)
# link_directories(kmc_sample)
# link_directories(kmc_CLI)

# target_link_libraries(GzipTest ZLIB::ZLIB)

# add_executable(kmc_dump kmc_dump/kmc_dump.cpp)

# add_executable(kmc_api ${kmc_api_sources})
# target_link_libraries(kmc_api Threads::Threads)

add_library(kmc_api SHARED ${kmc_core_sources} ${kmc_api_sources} ${kmc_kff_sources})
target_include_directories(kmc_api PUBLIC 
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        $<INSTALL_INTERFACE:include>)
target_link_libraries(kmc_api Threads::Threads ZLIB::ZLIB BZip2::BZip2)

add_executable(kmc_tools ${kmc_tools_sources} ${kmc_api_sources} ${kmc_kff_sources})
target_link_libraries(kmc_tools Threads::Threads ZLIB::ZLIB BZip2::BZip2)

add_executable(kmc_dump ${kmc_dump_sources} ${kmc_api_sources} ${kmc_kff_sources})
target_link_libraries(kmc_dump Threads::Threads ZLIB::ZLIB BZip2::BZip2)

add_executable(kmc ${kmc_cli_sources} kmc_api)
target_link_libraries(kmc Threads::Threads ZLIB::ZLIB BZip2::BZip2 kmc_api)

# add_executable(kmc kmc_CLI/kmc.cpp)
# install(TARGETS cimplot
#        EXPORT cimplot-targets
#        RUNTIME DESTINATION bin
#        LIBRARY DESTINATION lib
#        ARCHIVE DESTINATION lib
#        PUBLIC_HEADER DESTINATION include)
