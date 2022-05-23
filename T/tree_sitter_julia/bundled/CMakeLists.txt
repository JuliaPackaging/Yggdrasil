cmake_minimum_required(VERSION 3.13)
project(treesitter_julia)
set(CMAKE_C_STANDARD 99)

include_directories(tree-sitter/src)
file(GLOB SOURCE_JULIA tree-sitter/src/*.c)
add_library(treesitter_julia SHARED ${SOURCE_JULIA})

install(TARGETS treesitter_julia DESTINATION lib CONFIGURATIONS Release)
