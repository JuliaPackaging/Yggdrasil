configure_file(src/mkdsk_c/main.x ${CMAKE_BINARY_DIR}/mkdsk_main.c)
configure_file(src/mkdsk_c/mkdsk.pgm ${CMAKE_BINARY_DIR}/mkdsk.c)

set(MKDSK_SRCS
  src/mkdsk_c/addcom.c
  src/mkdsk_c/extmsi.c
  src/mkdsk_c/makvtx.c
  src/mkdsk_c/mkgrid.c
  src/mkdsk_c/mkvarr.c
  src/mkdsk_c/prcinf.c
  src/mkdsk_c/prcset.c
  src/mkdsk_c/prscml.c
  src/mkdsk_c/rc2cor.c
  src/mkdsk_c/rdffdi.c
  src/mkdsk_c/rdffpl.c
  src/mkdsk_c/rdgrd5.c
  src/mkdsk_c/wrtdsk.c
  src/mkdsk_c/zzpsxtnt.c
  src/mkdsk_c/zztrgnvx.c
  src/mkdsk_c/zzvoxscl.c
  src/mkdsk_c/zzwseg02.c)

add_executable(mkdsk ${CMAKE_BINARY_DIR}/mkdsk_main.c ${CMAKE_BINARY_DIR}/mkdsk.c ${MKDSK_SRCS})
target_link_libraries(mkdsk cspice csupport)

