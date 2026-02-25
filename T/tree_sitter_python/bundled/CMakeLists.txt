cmake_minimum_required(VERSION 3.13)
project(treesitter_python)
set(CMAKE_C_STANDARD 99)

include_directories(tree-sitter/src)
add_library(treesitter_python SHARED tree-sitter/src/parser.c tree-sitter/src/scanner.c)
add_compile_definitions(UINT8_MAX=255)

install(TARGETS treesitter_python DESTINATION lib CONFIGURATIONS Release)
