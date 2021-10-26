configure_file(src/dskbrief_c/main.x ${CMAKE_BINARY_DIR}/dskbrief_main.c)
configure_file(src/dskbrief_c/dskbrief.pgm ${CMAKE_BINARY_DIR}/dskbrief.c)

set(DSK_BRIEF_SRCS
  src/dskbrief_c/attcmp.c
  src/dskbrief_c/cortab.c
  src/dskbrief_c/dskb04.c
  src/dskbrief_c/dskd04.c
  src/dskbrief_c/dski04.c
  src/dskbrief_c/dspdsc.c
  src/dskbrief_c/dspgap.c
  src/dskbrief_c/grpseg.c
  src/dskbrief_c/prcinf.c
  src/dskbrief_c/sum02.c
  src/dskbrief_c/sum04.c)

add_executable(dskbrief ${CMAKE_BINARY_DIR}/dskbrief_main.c ${CMAKE_BINARY_DIR}/dskbrief.c ${DSK_BRIEF_SRCS})
target_link_libraries(dskbrief cspice csupport)

