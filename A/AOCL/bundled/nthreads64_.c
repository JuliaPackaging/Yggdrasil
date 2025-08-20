#include "blis.h"

// Declarations to match 'bli_thread.h' and export names:
BLIS_EXPORT_BLIS void    bli_thread_set_num_threads64_ ( dim_t value );
BLIS_EXPORT_BLIS dim_t   bli_thread_get_num_threads64_ ( void );

void bli_thread_set_num_threads64_
     (
       dim_t  nt
     )
{
        // Initialize BLIS.
        bli_init_auto();

        // Call the BLIS function.
        bli_thread_set_num_threads( nt );

        // Finalize BLIS.
        bli_finalize_auto();
}

dim_t bli_thread_get_num_threads64_ ()
{
        // Initialize BLIS.
        bli_init_auto();

        // Call the BLIS function.
        dim_t nt = bli_thread_get_num_threads( );

        // Finalize BLIS.
        bli_finalize_auto();

        return nt;
}

