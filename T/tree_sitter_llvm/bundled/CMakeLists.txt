cmake_minimum_required(VERSION 3.13)
project(treesitter_llvm)
set(CMAKE_C_STANDARD 99)

include_directories(tree-sitter/src)
file(GLOB SOURCE_LLVM tree-sitter/src/*.c)
add_library(treesitter_llvm SHARED ${SOURCE_LLVM})

install(TARGETS treesitter_llvm DESTINATION lib CONFIGURATIONS Release)
