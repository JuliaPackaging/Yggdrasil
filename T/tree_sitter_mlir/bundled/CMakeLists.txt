cmake_minimum_required(VERSION 3.13)
project(treesitter_mlir)
set(CMAKE_C_STANDARD 99)

include_directories(tree-sitter/src)
file(GLOB SOURCE_MLIR tree-sitter/src/*.c)
add_library(treesitter_mlir SHARED ${SOURCE_MLIR})

include(GNUInstallDirs)
install(TARGETS treesitter_mlir CONFIGURATIONS Release
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
