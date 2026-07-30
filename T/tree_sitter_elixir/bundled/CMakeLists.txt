cmake_minimum_required(VERSION 3.13)
project(treesitter_elixir)
set(CMAKE_C_STANDARD 99)

include_directories(tree-sitter/src)
add_library(treesitter_elixir SHARED tree-sitter/src/parser.c tree-sitter/src/scanner.c)

install(TARGETS treesitter_elixir DESTINATION lib CONFIGURATIONS Release)
