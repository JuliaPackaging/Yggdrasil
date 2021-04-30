configure_file(src/ckbref_c/main.x ${CMAKE_BINARY_DIR}/ckbrief_main.c)
configure_file(src/ckbref_c/ckbrief.pgm ${CMAKE_BINARY_DIR}/ckbrief.c)

set(CKBRIEF_SRCS
  src/ckbref_c/dispsm.c
  src/ckbref_c/fixuni.c
  src/ckbref_c/prinst.c
  src/ckbref_c/repmcw.c
  src/ckbref_c/timecn.c)

add_executable(ckbrief ${CMAKE_BINARY_DIR}/ckbrief_main.c ${CMAKE_BINARY_DIR}/ckbrief.c ${CKBRIEF_SRCS})
target_link_libraries(ckbrief cspice csupport)

