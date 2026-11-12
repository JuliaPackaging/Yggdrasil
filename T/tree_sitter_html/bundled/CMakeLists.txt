cmake_minimum_required(VERSION 3.13)
project(treesitter_html)
set(CMAKE_C_STANDARD 99)

include_directories(tree-sitter/src)
add_library(treesitter_html SHARED tree-sitter/src/parser.c tree-sitter/src/scanner.c)
add_compile_definitions(UINT8_MAX=0xFF)
add_compile_definitions(UINT16_MAX=0xFFFF)

install(TARGETS treesitter_html DESTINATION lib CONFIGURATIONS Release)
