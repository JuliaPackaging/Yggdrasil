configure_file(src/mkspk_c/main.x ${CMAKE_BINARY_DIR}/mkspk_main.c)
configure_file(src/mkspk_c/mkspk.pgm ${CMAKE_BINARY_DIR}/mkspk.c)

set(MKSPK_SRCS
  src/mkspk_c/chckdo.c
  src/mkspk_c/cmlarg.c
  src/mkspk_c/parsdo.c
  src/mkspk_c/redbuf.c
  src/mkspk_c/reorbd.c
  src/mkspk_c/setelm.c
  src/mkspk_c/setup.c
  src/mkspk_c/tle2spk.c)

add_executable(mkspk ${CMAKE_BINARY_DIR}/mkspk_main.c ${CMAKE_BINARY_DIR}/mkspk.c ${MKSPK_SRCS})
target_link_libraries(mkspk cspice csupport)

