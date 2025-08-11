cmake_minimum_required(VERSION 3.13)
project(treesitter_modelica)
set(CMAKE_C_STANDARD 99)

include_directories(tree-sitter/src)
add_library(treesitter_modelica SHARED tree-sitter/src/parser.c)

include(GNUInstallDirs)
install(TARGETS treesitter_modelica DESTINATION "${CMAKE_INSTALL_LIBDIR}" CONFIGURATIONS Release)
