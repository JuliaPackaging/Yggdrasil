configure_file(src/brief_c/main.x ${CMAKE_BINARY_DIR}/brief_main.c)
configure_file(src/brief_c/brief.pgm ${CMAKE_BINARY_DIR}/brief.c)

set(BRIEF_SRCS
  src/brief_c/disply.c
  src/brief_c/distim.c
  src/brief_c/filtem.c
  src/brief_c/getnam.c
  src/brief_c/maknam.c
  src/brief_c/objact.c
  src/brief_c/objadd.c
  src/brief_c/objcf1.c
  src/brief_c/objcf2.c
  src/brief_c/objchk.c
  src/brief_c/objcmp.c
  src/brief_c/objfnd.c
  src/brief_c/objget.c
  src/brief_c/objinl.c
  src/brief_c/objmod.c
  src/brief_c/objnth.c
  src/brief_c/objnxt.c
  src/brief_c/objrem.c
  src/brief_c/objsbc.c
  src/brief_c/objsbf.c
  src/brief_c/objset.c
  src/brief_c/objsiz.c
  src/brief_c/objval.c
  src/brief_c/prname.c
  src/brief_c/rndem.c
  src/brief_c/writit.c)

add_executable(brief ${CMAKE_BINARY_DIR}/brief_main.c ${CMAKE_BINARY_DIR}/brief.c ${BRIEF_SRCS})
target_link_libraries(brief cspice csupport)

