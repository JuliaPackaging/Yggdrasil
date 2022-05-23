configure_file(src/toxfr_c/main.x ${CMAKE_BINARY_DIR}/toxfr_main.c)
configure_file(src/toxfr_c/toxfr.pgm ${CMAKE_BINARY_DIR}/toxfr.c)

add_executable(toxfr ${CMAKE_BINARY_DIR}/toxfr_main.c ${CMAKE_BINARY_DIR}/toxfr.c)
target_link_libraries(toxfr cspice csupport)

