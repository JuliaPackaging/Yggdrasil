cmake_minimum_required(VERSION 3.13)
project(treesitter_spirv)
set(CMAKE_C_STANDARD 99)

include_directories(tree-sitter/src)
file(GLOB SOURCE_SPIRV tree-sitter/src/*.c)
add_library(treesitter_spirv SHARED ${SOURCE_SPIRV})

install(TARGETS treesitter_spirv DESTINATION lib CONFIGURATIONS Release)
