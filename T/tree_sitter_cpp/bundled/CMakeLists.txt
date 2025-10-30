cmake_minimum_required(VERSION 3.13)
project(treesitter_cpp)
set(CMAKE_C_STANDARD 11)

include_directories(tree-sitter/src)
add_library(treesitter_cpp SHARED tree-sitter/src/parser.c tree-sitter/src/scanner.c)

install(TARGETS treesitter_cpp DESTINATION lib CONFIGURATIONS Release)
