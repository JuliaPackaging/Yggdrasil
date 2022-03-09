configure_file(src/versn_c/main.x ${CMAKE_BINARY_DIR}/version_main.c)
configure_file(src/versn_c/version.pgm ${CMAKE_BINARY_DIR}/version.c)

add_executable(version ${CMAKE_BINARY_DIR}/version_main.c ${CMAKE_BINARY_DIR}/version.c)
target_link_libraries(version cspice csupport)

