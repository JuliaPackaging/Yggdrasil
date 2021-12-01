configure_file(src/msopck_c/main.x ${CMAKE_BINARY_DIR}/msopck_main.c)
configure_file(src/msopck_c/msopck.pgm ${CMAKE_BINARY_DIR}/msopck.c)

set(MSOPCK_SRCS
  src/msopck_c/linrot_m.c
  src/msopck_c/mkfclk.c
  src/msopck_c/zzmckdmp.c)

add_executable(msopck ${CMAKE_BINARY_DIR}/msopck_main.c ${CMAKE_BINARY_DIR}/msopck.c ${MSOPCK_SRCS})
target_link_libraries(msopck cspice csupport)

