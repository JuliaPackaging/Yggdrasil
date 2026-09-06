cmake_minimum_required(VERSION 3.13)
project(treesitter_nonmem)
set(CMAKE_C_STANDARD 99)

include_directories(tree-sitter/src)
file(GLOB SOURCE_NONMEM tree-sitter/src/*.c)
add_library(treesitter_nonmem SHARED ${SOURCE_NONMEM})

install(TARGETS treesitter_nonmem DESTINATION lib CONFIGURATIONS Release)
