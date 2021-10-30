#ifdef __cplusplus
extern "C" {
#endif
typedef double vec3d[3];
typedef double mat3d[3][3];

/* A mesh is represented as (nv, nf, mv, mf), where
 * int nv = number of vertices
 * int nf = number of faces
 * double *mv = matrix of vertex coordinates (row-wise)
 * int *mf = matrix of triangles (row-wise)
 *
 * Operation is:
 * 0: union
 * 1: intersection
 * 2: minus
 * 3: xor
 *
 * Places malloc()ed arrays (in row-major order) as mv3 and mf3.
 * Returns -1 on failure and 0 on success.
 */

int mesh_boolean(int op,
  int nv1, int nf1, const double *mv1, const int *mf1,
  int nv2, int nf2, const double *mv2, const int *mf2,
  int *nv3, int *nf3, double **mv3, int **mf3, int **index);
int minkowski_sum(int nv1, int nf1, const double *mv1, const int *mf1,
  int nv2, int nf2, const double *mv2, const int *mf2, int dim2,
  int *nv3, int *nf3, double **mv3, int **mf3, int **index);

int mesh_is_pwn(int nv, int nf, const double *mv, const int *mf);
/* Offsets surface (nv,nf,mv,mf) by `level` (to the outside)
 * using a marching-cubes algorithm with largest side subdivided `grid`
 * times. Returns 0 on success, -1 on failure. */
int offset_surface(int nv, int nf, const double *mv, const int *mf,
	double level, int grid, int *nv1, int *nf1, double **mv1, int **mf1);

int decimate(int nv, int nf, const double *mv, const int *mf, int faces,
	int *nvout, int *nfout, double **mvout, int **mfout, int **index);
int loop(int nv, int nf, const double *mv, const int *mf, int n,
	int *nvout, int *nfout, double **mvout, int **mfout);
/* int reorient_facets_raycast(int nv, int nf, const double *mv, const int *mf, */
/* 	int **mfout, int **flipped); */
double centroid_and_volume(int nv, int nf, const double *mv, const int *mf,
	vec3d *c);
int intersect_with_half_space(int nv, int nf,
	const double *mv, const int *mf,
	const vec3d *p, const vec3d *n,
	int *nvout, int *nfout, double **mvout, int **mfout, int **index);
int swept_volume(int nv, int nf, const double *mv, const int *mf,
	void (*ctransform)(double, mat3d*, vec3d*),
	size_t steps, size_t gridres, double isolevel,
	int *nvout, int *nfout, double **mvout, int **mfout);
#ifdef __cplusplus
} // extern
#endif
