#include <string.h>
#include <cholmod.h>


int main(int argc, char *argv[]) {
  printf("const SuiteSparse_long = Int%zd\n", 8*sizeof(SuiteSparse_long));

  printf("const cholmod_version = VersionNumber(%d,%d,%d)\n",
         CHOLMOD_MAIN_VERSION, CHOLMOD_SUB_VERSION, CHOLMOD_SUBSUB_VERSION);

  printf("const cholmod_common_sizeof = %zd\n", sizeof(cholmod_common));

  printf("const cholmod_common_offset_dbound            = %zd\n", offsetof(cholmod_common, dbound));
  printf("const cholmod_common_offset_maxrank           = %zd\n", offsetof(cholmod_common, maxrank));
  printf("const cholmod_common_offset_supernodal_switch = %zd\n", offsetof(cholmod_common, supernodal_switch));
  printf("const cholmod_common_offset_supernodal        = %zd\n", offsetof(cholmod_common, supernodal));
  printf("const cholmod_common_offset_final_asis        = %zd\n", offsetof(cholmod_common, final_asis));
  printf("const cholmod_common_offset_final_super       = %zd\n", offsetof(cholmod_common, final_super));
  printf("const cholmod_common_offset_final_ll          = %zd\n", offsetof(cholmod_common, final_ll));
  printf("const cholmod_common_offset_final_pack        = %zd\n", offsetof(cholmod_common, final_pack));
  printf("const cholmod_common_offset_final_monotonic   = %zd\n", offsetof(cholmod_common, final_monotonic));
  printf("const cholmod_common_offset_final_resymbol    = %zd\n", offsetof(cholmod_common, final_resymbol));
  printf("const cholmod_common_offset_prefer_zomplex    = %zd\n", offsetof(cholmod_common, prefer_zomplex));
  printf("const cholmod_common_offset_prefer_upper      = %zd\n", offsetof(cholmod_common, prefer_upper));
  printf("const cholmod_common_offset_print             = %zd\n", offsetof(cholmod_common, print));
  printf("const cholmod_common_offset_precise           = %zd\n", offsetof(cholmod_common, precise));
  printf("const cholmod_common_offset_nmethods          = %zd\n", offsetof(cholmod_common, nmethods));
  printf("const cholmod_common_offset_selected          = %zd\n", offsetof(cholmod_common, selected));
  printf("const cholmod_common_offset_postorder         = %zd\n", offsetof(cholmod_common, postorder));
  printf("const cholmod_common_offset_itype             = %zd\n", offsetof(cholmod_common, itype));
  printf("const cholmod_common_offset_dtype             = %zd\n", offsetof(cholmod_common, dtype));

  return 0;
}
