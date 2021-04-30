configure_file(src/tobin_c/main.x ${CMAKE_BINARY_DIR}/tobin_main.c)
configure_file(src/tobin_c/tobin.pgm ${CMAKE_BINARY_DIR}/tobin.c)

add_executable(tobin ${CMAKE_BINARY_DIR}/tobin_main.c ${CMAKE_BINARY_DIR}/tobin.c src/tobin_c/zzconvtb.c)
target_link_libraries(tobin cspice csupport)

