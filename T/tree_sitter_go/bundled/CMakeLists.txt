cmake_minimum_required(VERSION 3.13)
project(treesitter_go)
set(CMAKE_C_STANDARD 99)

include_directories(tree-sitter/src)
add_library(treesitter_go SHARED tree-sitter/src/parser.c)

install(TARGETS treesitter_go DESTINATION lib CONFIGURATIONS Release)
