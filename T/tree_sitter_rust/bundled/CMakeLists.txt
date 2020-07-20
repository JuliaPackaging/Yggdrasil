cmake_minimum_required(VERSION 3.13)
project(treesitter_rust)
set(CMAKE_C_STANDARD 99)

include_directories(tree-sitter/src)
add_library(treesitter_rust SHARED tree-sitter/src/parser.c tree-sitter/src/scanner.c)

install(TARGETS treesitter_rust DESTINATION lib CONFIGURATIONS Release)
