configure_file(src/spacit_c/main.x ${CMAKE_BINARY_DIR}/spacit_main.c)
configure_file(src/spacit_c/spacit.pgm ${CMAKE_BINARY_DIR}/spacit.c)

set(SPACIT_SRCS
  src/spacit_c/ckgss.c
  src/spacit_c/ckwss.c
  src/spacit_c/getchr.c
  src/spacit_c/getint.c
  src/spacit_c/pckgss.c
  src/spacit_c/pckwss.c
  src/spacit_c/spab2t.c
  src/spacit_c/spalog.c
  src/spacit_c/spardc.c
  src/spacit_c/spasum.c
  src/spacit_c/spat2b.c
  src/spacit_c/spkgss.c
  src/spacit_c/spkwss.c
  src/spacit_c/sumck.c
  src/spacit_c/sumek.c
  src/spacit_c/sumpck.c
  src/spacit_c/sumspk.c
  src/spacit_c/zzconvtb.c)

add_executable(spacit ${CMAKE_BINARY_DIR}/spacit_main.c ${CMAKE_BINARY_DIR}/spacit.c ${SPACIT_SRCS})
target_link_libraries(spacit cspice csupport)

