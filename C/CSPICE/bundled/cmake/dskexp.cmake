configure_file(src/dskexp_c/main.x ${CMAKE_BINARY_DIR}/dskexp_main.c)
configure_file(src/dskexp_c/dskexp.pgm ${CMAKE_BINARY_DIR}/dskexp.c)

add_executable(dskexp ${CMAKE_BINARY_DIR}/dskexp_main.c ${CMAKE_BINARY_DIR}/dskexp.c)
target_link_libraries(dskexp cspice csupport)

