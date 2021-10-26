configure_file(src/commnt_c/main.x ${CMAKE_BINARY_DIR}/commnt_main.c)
configure_file(src/commnt_c/commnt.pgm ${CMAKE_BINARY_DIR}/commnt.c)

set(COMMNT_SRCS src/commnt_c/clcomm.c)

add_executable(commnt ${CMAKE_BINARY_DIR}/commnt_main.c ${CMAKE_BINARY_DIR}/commnt.c ${COMMNT_SRCS})
target_link_libraries(commnt cspice csupport)

