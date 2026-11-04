cmake_minimum_required(VERSION 3.13)
project(treesitter_gcn)
set(CMAKE_C_STANDARD 99)

include_directories(tree-sitter/src)
file(GLOB SOURCE_GCN tree-sitter/src/*.c)
add_library(treesitter_gcn SHARED ${SOURCE_GCN})

install(TARGETS treesitter_gcn DESTINATION lib CONFIGURATIONS Release)
