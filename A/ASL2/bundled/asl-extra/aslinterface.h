// ===============================================================
// Generic AMPL interface to facilitate usage from other languages.
// Adaptation of Dominique Orban's interface (solvers.tgz) to the
// multithreaded ASL (solvers2.tgz), in which evaluations operate
// on a given EvalWorkspace.
//
// Two families of functions are exposed:
//   * the original ASL-only entry points, which evaluate through
//     the default workspace asl->i.Ew0 (drop-in compatible with
//     the solvers.tgz interface);
//   * _ew variants taking an explicit EvalWorkspace, allocated
//     with asl_ewalloc(). Distinct workspaces may evaluate
//     concurrently from different threads.
//
// All workspaces are freed together with the ASL by asl_finalize().
// ===============================================================

#include <stdint.h>
#include <stddef.h>
#include "asl_pfgh.h"

// ==========================================================================

//
//        P r o t o t y p e s   f o r   m o d u l e   f u n c t i o n s
//

// ==========================================================================

#ifdef __cplusplus
extern "C" {
#endif

typedef struct ASL ASL;

ASL *asl_init(const char *stub);
void asl_finalize(ASL *asl);
void asl_write_sol(ASL *asl, const char *msg, double *x, double *y);

// Allocate an additional evaluation workspace. The returned workspace is
// owned by the ASL and is released by asl_finalize(); there is no
// separate deallocation function. The default workspace used by the
// ASL-only evaluation functions below is available as asl_ew0().
EvalWorkspace *asl_ewalloc(ASL *asl);
EvalWorkspace *asl_ew0(ASL *asl);

int asl_objtype(ASL *asl);
int asl_nlo(    ASL *asl);
int asl_nzo(    ASL *asl);
int asl_nvar(   ASL *asl);
int asl_nbv(    ASL *asl);
int asl_niv(    ASL *asl);
int asl_nlvb(   ASL *asl);
int asl_nlvo(   ASL *asl);
int asl_nlvc(   ASL *asl);
int asl_nlvbi(  ASL *asl);
int asl_nlvci(  ASL *asl);
int asl_nlvoi(  ASL *asl);
int asl_nwv(    ASL *asl);
int asl_ncon(   ASL *asl);
int asl_nlc(    ASL *asl);
int asl_lnc(    ASL *asl);
int asl_nlnc(   ASL *asl);
int asl_nnzj(   ASL *asl);
int asl_nnzh(   ASL *asl);
int asl_islp(   ASL *asl);
int asl_n_cc(   ASL *asl);

double *asl_x0(  ASL *asl);
double *asl_y0(  ASL *asl);
double *asl_lvar(ASL *asl);
double *asl_uvar(ASL *asl);
double *asl_lcon(ASL *asl);
double *asl_ucon(ASL *asl);
int    *asl_cvar(ASL *asl);

void asl_varscale(ASL *asl, double *s, int *err);
void asl_lagscale(ASL *asl, double  s, int *err);
void asl_conscale(ASL *asl, double *s, int *err);

// Evaluations through the default workspace (drop-in compatible).

double  asl_obj(     ASL *asl, double *x, int *err);
void    asl_grad(    ASL *asl, double *x, double *g, int *err);
void    asl_cons(    ASL *asl, double *x, double *c, int *err);
double  asl_jcon(    ASL *asl, double *x, int j, int *err);
void    asl_jcongrad(ASL *asl, double *x, double *g, int j, int *err);
void    asl_hprod(   ASL *asl, double *y, double *v, double *hv, double w);
void    asl_hvcompd( ASL *asl, double *v, double *hv, int nobj);
void    asl_ghjvprod(ASL *asl, double *g, double *v, double *ghjv);

size_t asl_sparse_congrad_nnz(ASL *asl, int j);
void asl_sparse_congrad(
    ASL *asl, double *x, int j, int *inds, double *vals, int *err);
void asl_jac( ASL *asl, double *x, int *rows, int *cols, double *vals, int *err);
void asl_jac_structure( ASL *asl, int *rows, int *cols);
void asl_jacval( ASL *asl, double *x, double *vals, int *err);
void asl_hess(
    ASL *asl, double *y, double w, int *rows, int *cols, double *vals);
void asl_hess_structure(ASL *asl, int *rows, int *cols);
void asl_hessval(ASL *asl, double *y, double w, double *vals);

// Evaluations on an explicit workspace. Distinct workspaces may be used
// concurrently from different threads; a single workspace must not.
// Note: the Hessian sparsity pattern is established per workspace, so
// asl_nnzh_ew() must be called on a workspace before asl_hess_ew(),
// asl_hess_structure_ew() or asl_hessval_ew() on that same workspace.

double  asl_obj_ew(     EvalWorkspace *ew, double *x, int *err);
void    asl_grad_ew(    EvalWorkspace *ew, double *x, double *g, int *err);
void    asl_cons_ew(    EvalWorkspace *ew, double *x, double *c, int *err);
double  asl_jcon_ew(    EvalWorkspace *ew, double *x, int j, int *err);
void    asl_jcongrad_ew(EvalWorkspace *ew, double *x, double *g, int j, int *err);
void    asl_hprod_ew(   EvalWorkspace *ew, double *y, double *v, double *hv, double w);
void    asl_hvcompd_ew( EvalWorkspace *ew, double *v, double *hv, int nobj);
void    asl_ghjvprod_ew(EvalWorkspace *ew, double *g, double *v, double *ghjv);

// Warning: this function temporarily flips asl->i.congrd_mode, which is
// state shared by all workspaces of this ASL. It must therefore not run
// concurrently with any other evaluation on the same ASL.
void asl_sparse_congrad_ew(
    EvalWorkspace *ew, double *x, int j, int *inds, double *vals, int *err);

void asl_jac_ew( EvalWorkspace *ew, double *x, int *rows, int *cols, double *vals, int *err);
void asl_jacval_ew( EvalWorkspace *ew, double *x, double *vals, int *err);
int  asl_nnzh_ew(EvalWorkspace *ew);
void asl_hess_ew(
    EvalWorkspace *ew, double *y, double w, int *rows, int *cols, double *vals);
void asl_hess_structure_ew(EvalWorkspace *ew, int *rows, int *cols);
void asl_hessval_ew(EvalWorkspace *ew, double *y, double w, double *vals);

#ifdef __cplusplus
}  // extern "C"
#endif
