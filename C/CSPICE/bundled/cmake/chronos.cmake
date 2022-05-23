configure_file(src/chrnos_c/main.x ${CMAKE_BINARY_DIR}/chronos_main.c)
configure_file(src/chrnos_c/chronos.pgm ${CMAKE_BINARY_DIR}/chronos.c)

set(CHRONOS_SRCS
  src/chrnos_c/crcnst.c
  src/chrnos_c/cronos.c
  src/chrnos_c/dsplay.c
  src/chrnos_c/ls.c
  src/chrnos_c/lstmid.c
  src/chrnos_c/speakr.c)

add_executable(chronos ${CMAKE_BINARY_DIR}/chronos_main.c ${CMAKE_BINARY_DIR}/chronos.c ${CHRONOS_SRCS})
target_link_libraries(chronos cspice csupport)

