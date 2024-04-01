cmake_minimum_required(VERSION 3.13)
project(treesitter_ocaml)
set(CMAKE_C_STANDARD 99)

include_directories(tree-sitter/ocaml/src)
add_library(treesitter_ocaml SHARED tree-sitter/ocaml/src/parser.c tree-sitter/ocaml/src/scanner.cc)

install(TARGETS treesitter_ocaml DESTINATION lib CONFIGURATIONS Release)
