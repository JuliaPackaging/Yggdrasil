
#include <libqhull_r/libqhull_r.h>

qhT* new_qhull_handler();
int delaunay_init_and_compute(qhT *qh, int dim, int numpoints, coordT *points, int* numcells, const char* options);
int delaunay_fill_cells(qhT *qh, int dim, int num_cells, int *cells);
int delaunay_free(qhT *qh);

