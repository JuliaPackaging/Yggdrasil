cmake_minimum_required(VERSION 3.13)
project(treesitter)
set(CMAKE_C_STANDARD 99)

include_directories(tree-sitter/lib/include tree-sitter/lib/src)
add_library(treesitter SHARED tree-sitter/lib/src/lib.c)

install(TARGETS treesitter DESTINATION lib CONFIGURATIONS Release)
