cmake_minimum_required(VERSION 3.13)
project(treesitter_typescript)
set(CMAKE_C_STANDARD 99)

include_directories(tree-sitter/typescript/src)
add_library(treesitter_typescript SHARED tree-sitter/typescript/src/parser.c tree-sitter/typescript/src/scanner.c)

install(TARGETS treesitter_typescript DESTINATION lib CONFIGURATIONS Release)
