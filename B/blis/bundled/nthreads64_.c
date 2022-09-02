#include "blis.h"

void bli_thread_set_num_threads64_
     (
       const int nt
     )
{
        // Initialize BLIS.
        bli_init_auto();

        // Call the BLIS function.
        bli_thread_set_num_threads( nt );

        // Finalize BLIS.
        bli_finalize_auto();
}

int bli_thread_get_num_threads64_ ()
{
        // Initialize BLIS.
        bli_init_auto();

        // Call the BLIS function.
        dim_t nt = bli_thread_get_num_threads( );

        // Finalize BLIS.
        bli_finalize_auto();

        return nt;
}

