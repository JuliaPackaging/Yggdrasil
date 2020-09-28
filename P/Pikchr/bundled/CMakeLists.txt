# Specify the minimum version for CMake
cmake_minimum_required(VERSION 3.10)

add_library(pikchr SHARED pikchr.c)

install(TARGETS pikchr DESTINATION lib)
