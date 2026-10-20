cmake_minimum_required(VERSION 3.13)
project(treesitter_ptx)
set(CMAKE_C_STANDARD 99)

include_directories(tree-sitter/src)
file(GLOB SOURCE_PTX tree-sitter/src/*.c)
add_library(treesitter_ptx SHARED ${SOURCE_PTX})

install(TARGETS treesitter_ptx DESTINATION lib CONFIGURATIONS Release)
