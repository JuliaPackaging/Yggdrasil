configure_file(src/spkmrg_c/main.x ${CMAKE_BINARY_DIR}/spkmerge_main.c)
configure_file(src/spkmrg_c/spkmerge.pgm ${CMAKE_BINARY_DIR}/spkmerge.c)

set(SPKMERGE_SRCS
  src/spkmrg_c/cparse_2.c
  src/spkmrg_c/rdcmd.c
  src/spkmrg_c/wrdnln.c)

add_executable(spkmerge ${CMAKE_BINARY_DIR}/spkmerge_main.c ${CMAKE_BINARY_DIR}/spkmerge.c ${SPKMERGE_SRCS})
target_link_libraries(spkmerge cspice csupport)

