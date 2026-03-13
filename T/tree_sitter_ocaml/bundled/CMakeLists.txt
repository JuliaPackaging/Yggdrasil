cmake_minimum_required(VERSION 3.13)
project(treesitter_ocaml)
set(CMAKE_C_STANDARD 99)

# Build ocaml grammar (main implementation files)
include_directories(tree-sitter/grammars/ocaml/src)
add_library(treesitter_ocaml SHARED tree-sitter/grammars/ocaml/src/parser.c tree-sitter/grammars/ocaml/src/scanner.c)

# Build ocaml_interface grammar (interface files)
include_directories(tree-sitter/grammars/interface/src)
add_library(treesitter_ocaml_interface SHARED tree-sitter/grammars/interface/src/parser.c tree-sitter/grammars/interface/src/scanner.c)

# Build ocaml_type grammar (standalone type parsing)
include_directories(tree-sitter/grammars/type/src)
add_library(treesitter_ocaml_type SHARED tree-sitter/grammars/type/src/parser.c tree-sitter/grammars/type/src/scanner.c)

# Install all three libraries
install(TARGETS treesitter_ocaml treesitter_ocaml_interface treesitter_ocaml_type DESTINATION lib CONFIGURATIONS Release)
