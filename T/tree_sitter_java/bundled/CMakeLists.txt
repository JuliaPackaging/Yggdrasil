cmake_minimum_required(VERSION 3.13)
project(treesitter_java)
set(CMAKE_C_STANDARD 99)

include_directories(tree-sitter/src)
add_library(treesitter_java SHARED tree-sitter/src/parser.c)

install(TARGETS treesitter_java DESTINATION lib CONFIGURATIONS Release)
