cmake_minimum_required(VERSION 3.13)
project(treesitter_php)
set(CMAKE_C_STANDARD 99)

# Build php parser (with HTML interpolation support)
include_directories(tree-sitter/php/src)
add_library(treesitter_php SHARED tree-sitter/php/src/parser.c tree-sitter/php/src/scanner.c)

# Build php_only parser (pure PHP, no HTML interpolation)
include_directories(tree-sitter/php_only/src)
add_library(treesitter_php_only SHARED tree-sitter/php_only/src/parser.c tree-sitter/php_only/src/scanner.c)

# Install both libraries
install(TARGETS treesitter_php treesitter_php_only DESTINATION lib CONFIGURATIONS Release)
