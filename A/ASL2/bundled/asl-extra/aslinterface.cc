// ===============================================================
// Generic AMPL interface to facilitate usage from other languages.
// Adaptation of Dominique Orban's interface (solvers.tgz) to the
// multithreaded ASL (solvers2.tgz).
// ===============================================================

#include "aslinterface.h"

#include <cstring>
#include <cstdlib>

// Module functions.

static real *allocate(ASL *asl, int size) {
  return static_cast<real *>(M1alloc(size * sizeof(real)));
}

ASL *asl_init(const char *stub) {
  ASL *asl = ASL_alloc(ASL_read_pfgh);
  if (!asl) return NULL;

  FILE *ampl_file = jac0dim(stub, static_cast<fint>(strlen(stub)));

  // Allocate room to store problem data
  if (!(asl->i.X0_    = allocate(asl, asl->i.n_var_))) return NULL;
  if (!(asl->i.LUv_   = allocate(asl, asl->i.n_var_))) return NULL;
  if (!(asl->i.Uvx_   = allocate(asl, asl->i.n_var_))) return NULL;
  if (!(asl->i.pi0_   = allocate(asl, asl->i.n_con_))) return NULL;
  if (!(asl->i.LUrhs_ = allocate(asl, asl->i.n_con_))) return NULL;
  if (!(asl->i.Urhsx_ = allocate(asl, asl->i.n_con_))) return NULL;

  // Read in ASL structure
  asl->i.want_xpi0_ = 3;        // Read primal and dual estimates
  pfgh_read(ampl_file, 0);      // pfgh_read closes the file.

  return asl;
}

void asl_write_sol(ASL *asl, const char *msg, double *x, double *y) {
  write_sol_ASL(asl, msg, x, y, 0); // Do not handle Option_Info for now.
}

void asl_finalize(ASL *asl) {
  ASL_free(&asl);
}

// Workspaces. The default workspace asl->i.Ew0 is allocated during
// pfgh_read; additional workspaces come from asl->p.EWalloc and are
// chained into the ASL, which frees them all in ASL_free.

EvalWorkspace *asl_ewalloc(ASL *asl) {
  return asl->p.EWalloc(asl);
}

EvalWorkspace *asl_ew0(ASL *asl) {
  return asl->i.Ew0;
}

// Problem setup.

int asl_objtype(ASL *asl) {
  return asl->i.objtype_[0];  // 0 means minimization problem.
}

int asl_nlo(ASL *asl) {
  return asl->i.nlo_;
}

int asl_nzo(ASL *asl) {
  return asl->i.nzo_;
}

//   Variables.

int asl_nvar(ASL *asl) {
  return asl->i.n_var_;
}

int asl_nbv(ASL *asl) {
  return asl->i.nbv_;
}

int asl_niv(ASL *asl) {
  return asl->i.niv_;
}

int asl_nlvb(ASL *asl) {
  return asl->i.nlvb_;
}

int asl_nlvo(ASL *asl) {
  return asl->i.nlvo_;
}

int asl_nlvc(ASL *asl) {
  return asl->i.nlvc_;
}

int asl_nlvbi(ASL *asl) {
  return asl->i.nlvbi_;
}

int asl_nlvci(ASL *asl) {
  return asl->i.nlvci_;
}

int asl_nlvoi(ASL *asl) {
  return asl->i.nlvoi_;
}

int asl_nwv(ASL *asl) {
  return asl->i.nwv_;
}

//   Constraints.

int asl_ncon(ASL *asl) {
  return asl->i.n_con_;
}

int asl_nlc(ASL *asl) {
  return asl->i.nlc_;
}

int asl_lnc(ASL *asl) {
  return asl->i.lnc_;
}

int asl_nlnc(ASL *asl) {
  return asl->i.nlnc_;
}

int asl_n_cc(ASL *asl) {
  return asl->i.n_cc_;
}

int asl_nnzj(ASL *asl) {
  return asl->i.nzc_;
}

int asl_nnzh_ew(EvalWorkspace *ew) {
  ASL *asl = ew->asl;
  return static_cast<int>(asl->p.Sphset(ew, 0, -1, 1, 1, 1));
}

int asl_nnzh(ASL *asl) {
  return asl_nnzh_ew(asl->i.Ew0);
}

int asl_islp(ASL *asl) {
  return ((asl->i.nlo_ + asl->i.nlc_ + asl->i.nlnc_) > 0 ? 0 : 1);
}

double *asl_x0(ASL *asl) {
  return asl->i.X0_;
}

double *asl_y0(ASL *asl) {
  return asl->i.pi0_;
}

double *asl_lvar(ASL *asl) {
  return asl->i.LUv_;
}

double *asl_uvar(ASL *asl) {
  return asl->i.Uvx_;
}

double *asl_lcon(ASL *asl) {
  return asl->i.LUrhs_;
}

double *asl_ucon(ASL *asl) {
  return asl->i.Urhsx_;
}

int *asl_cvar(ASL *asl) {
  return asl->i.cvar_;
}

// Scaling.

void asl_varscale(ASL *asl, double *s, int *err) {
  fint ne = (fint)0;
  int this_nvar = asl->i.n_var_;

  for (int i = 0; i < this_nvar; i++) {
    varscale_ASL(asl, i, s[i], &ne);
    if (ne)
      *err = (int)ne;
    else
      *err = 0;
    if (ne) return;
  }
}

void asl_lagscale(ASL *asl, double s, int *err) {
  fint ne = (fint)0;
  lagscale_ASL(asl, s, &ne);
  if (ne)
    *err = (int)ne;
  else
    *err = 0;
}

void asl_conscale(ASL *asl, double *s, int *err) {
  fint ne = (fint)0;
  int this_ncon = asl->i.n_con_;

  for (int j = 0; j < this_ncon; j++) {
    conscale_ASL(asl, j, s[j], &ne);
    if (ne)
      *err = (int)ne;
    else
      *err = 0;
    if (ne) return;
  }
}

// Objective.

double asl_obj_ew(EvalWorkspace *ew, double *x, int *err) {
  ASL *asl = ew->asl;
  fint ne = (fint)0;
  double f = asl->p.Objval(ew, 0, x, &ne);
  if (ne)
    *err = (int)ne;
  else
    *err = 0;
  return f;
}

double asl_obj(ASL *asl, double *x, int *err) {
  return asl_obj_ew(asl->i.Ew0, x, err);
}

void asl_grad_ew(EvalWorkspace *ew, double *x, double *g, int *err) {
  ASL *asl = ew->asl;
  fint ne = (fint)0;
  asl->p.Objgrd(ew, 0, x, g, &ne);
  if (ne)
    *err = (int)ne;
  else
    *err = 0;
}

void asl_grad(ASL *asl, double *x, double *g, int *err) {
  asl_grad_ew(asl->i.Ew0, x, g, err);
}

// Constraints and Jacobian.

void asl_cons_ew(EvalWorkspace *ew, double *x, double *c, int *err) {
  ASL *asl = ew->asl;
  fint ne = (fint)0;
  asl->p.Conval(ew, x, c, &ne);
  if (ne)
    *err = (int)ne;
  else
    *err = 0;
}

void asl_cons(ASL *asl, double *x, double *c, int *err) {
  asl_cons_ew(asl->i.Ew0, x, c, err);
}

double asl_jcon_ew(EvalWorkspace *ew, double *x, int j, int *err) {
  ASL *asl = ew->asl;
  fint ne = (fint)0;
  double cj = asl->p.Conival(ew, j, x, &ne);
  if (ne)
    *err = (int)ne;
  else
    *err = 0;
  return cj;
}

double asl_jcon(ASL *asl, double *x, int j, int *err) {
  return asl_jcon_ew(asl->i.Ew0, x, j, err);
}

void asl_jcongrad_ew(EvalWorkspace *ew, double *x, double *g, int j, int *err) {
  ASL *asl = ew->asl;
  fint ne = (fint)0;
  asl->p.Congrd(ew, j, x, g, &ne);
  if (ne)
    *err = (int)ne;
  else
    *err = 0;
}

void asl_jcongrad(ASL *asl, double *x, double *g, int j, int *err) {
  asl_jcongrad_ew(asl->i.Ew0, x, g, j, err);
}

size_t asl_sparse_congrad_nnz(ASL *asl, int j) {
  size_t nzgj = 0;
  for (cgrad *cg = asl->i.Cgrad_[j]; cg; cg = cg->next) nzgj++;
  return nzgj;
}

void asl_sparse_congrad_ew(
    EvalWorkspace *ew, double *x, int j, int *inds, double *vals, int *err) {
  ASL *asl = ew->asl;
  int congrd_mode_bkup = asl->i.congrd_mode;
  asl->i.congrd_mode = 1;  // Sparse gradient mode (shared ASL state!).

  fint ne = (fint)0;
  asl->p.Congrd(ew, j, x, vals, &ne);
  if (ne)
    *err = (int)ne;
  else
    *err = 0;
  if (ne) {
    asl->i.congrd_mode = congrd_mode_bkup;
    return;
  }

  int k = 0;
  for (cgrad *cg = asl->i.Cgrad_[j]; cg; cg = cg->next)
    inds[k++] = cg->varno;

  asl->i.congrd_mode = congrd_mode_bkup;  // Restore gradient mode.
}

void asl_sparse_congrad(
    ASL *asl, double *x, int j, int *inds, double *vals, int *err) {
  asl_sparse_congrad_ew(asl->i.Ew0, x, j, inds, vals, err);
}

// Evaluate Jacobian at x in triplet form (rows, vals, cols).
void asl_jac_ew(
    EvalWorkspace *ew, double *x, int *rows, int *cols, double *vals, int *err) {
  ASL *asl = ew->asl;
  int this_ncon = asl->i.n_con_;

  fint ne = (fint)0;
  asl->p.Jacval(ew, x, vals, &ne);
  if (ne)
    *err = (int)ne;
  else
    *err = 0;
  if (ne) return;

  // Fill in sparsity pattern.
  for (int j = 0; j < this_ncon; j++)
    for (cgrad *cg = asl->i.Cgrad_[j]; cg; cg = cg->next) {
      rows[cg->goff] = j;
      cols[cg->goff] = cg->varno;
    }
}

void asl_jac(ASL *asl, double *x, int *rows, int *cols, double *vals, int *err) {
  asl_jac_ew(asl->i.Ew0, x, rows, cols, vals, err);
}

// Evaluate Jacobian sparsity pattern (rows, cols).
void asl_jac_structure(ASL *asl, int *rows, int *cols) {
  int this_ncon = asl->i.n_con_;

  // Fill in sparsity pattern.
  for (int j = 0; j < this_ncon; j++)
    for (cgrad *cg = asl->i.Cgrad_[j]; cg; cg = cg->next) {
      rows[cg->goff] = j;
      cols[cg->goff] = cg->varno;
    }
}

// Evaluate Jacobian at x as if in triplet form, but only fill in the values.
void asl_jacval_ew(EvalWorkspace *ew, double *x, double *vals, int *err) {
  ASL *asl = ew->asl;
  fint ne = (fint)0;
  asl->p.Jacval(ew, x, vals, &ne);
  if (ne)
    *err = (int)ne;
  else
    *err = 0;
}

void asl_jacval(ASL *asl, double *x, double *vals, int *err) {
  asl_jacval_ew(asl->i.Ew0, x, vals, err);
}

// Hessian.

void asl_hprod_ew(EvalWorkspace *ew, double *y, double *v, double *hv, double w) {
  ASL *asl = ew->asl;
  double ow = w;
  asl->p.Hvinit(ew, asl->p.ihd_limit_, 0, NULL, y);
  asl->p.Hvcomp(ew, hv, v, -1, &ow, y); // nobj=-1 so ow takes precedence.
}

void asl_hprod(ASL *asl, double *y, double *v, double *hv, double w) {
  asl_hprod_ew(asl->i.Ew0, y, v, hv, w);
}

void asl_hvcompd_ew(EvalWorkspace *ew, double *v, double *hv, int nobj) {
  ASL *asl = ew->asl;
  asl->p.Hvcompd(ew, hv, v, nobj);
}

void asl_hvcompd(ASL *asl, double *v, double *hv, int nobj) {
  asl_hvcompd_ew(asl->i.Ew0, v, hv, nobj);
}

void asl_ghjvprod_ew(EvalWorkspace *ew, double *g, double *v, double *ghjv) {
  ASL *asl = ew->asl;
  int this_ncon = asl->i.n_con_;
  int this_nvar = asl->i.n_var_;
  int this_nlc  = asl->i.nlc_;
  double *hv    = static_cast<double *>(Malloc(this_nvar * sizeof(real)));

  // Process nonlinear constraints.
  for (int j = 0 ; j < this_nlc; j++) {
    asl->p.Hvcompd(ew, hv, v, j);

    // Compute dot product g'Hi*v. Should use BLAS.
    double prod = 0;
    for (int i = 0; i < this_nvar; i++)
      prod += (hv[i] * g[i]);
    ghjv[j] = prod;
  }
  free(hv);

  // All terms corresponding to linear constraints are zero.
  for (int j = this_nlc; j < this_ncon; j++) ghjv[j] = 0.;
}

void asl_ghjvprod(ASL *asl, double *g, double *v, double *ghjv) {
  asl_ghjvprod_ew(asl->i.Ew0, g, v, ghjv);
}

// Return Hessian at (x,y) in triplet form (rows, vals, cols).
// asl_nnzh_ew must have been called previously on this workspace.
void asl_hess_ew(
    EvalWorkspace *ew, double *y, double w, int *rows, int *cols, double *vals) {
  ASL *asl = ew->asl;
  double ow = w;
  asl->p.Sphes(ew, 0, vals, -1, &ow, y);

  // Fill in sparsity pattern.
  SputInfo *spi = ew->Sputinfo;
  int k = 0;
  for (fint i = 0; i < asl->i.n_var_; i++) {
    for (fint j = spi->hcolstarts[i]; j < spi->hcolstarts[i+1]; j++) {
      rows[k] = static_cast<int>(spi->hrownos[j]);
      cols[k] = static_cast<int>(i);
      k++;
    }
  }
}

void asl_hess(
    ASL *asl, double *y, double w, int *rows, int *cols, double *vals) {
  asl_hess_ew(asl->i.Ew0, y, w, rows, cols, vals);
}

// Return Hessian sparsity pattern (rows, cols).
// asl_nnzh_ew must have been called previously on this workspace.
void asl_hess_structure_ew(EvalWorkspace *ew, int *rows, int *cols) {
  ASL *asl = ew->asl;
  SputInfo *spi = ew->Sputinfo;
  int k = 0;
  for (fint i = 0; i < asl->i.n_var_; i++) {
    for (fint j = spi->hcolstarts[i]; j < spi->hcolstarts[i+1]; j++) {
      rows[k] = static_cast<int>(spi->hrownos[j]);
      cols[k] = static_cast<int>(i);
      k++;
    }
  }
}

void asl_hess_structure(ASL *asl, int *rows, int *cols) {
  asl_hess_structure_ew(asl->i.Ew0, rows, cols);
}

// Return Hessian at (x,y) as if in triplet form, but only fill in the values.
void asl_hessval_ew(EvalWorkspace *ew, double *y, double w, double *vals) {
  ASL *asl = ew->asl;
  double ow = w;
  asl->p.Sphes(ew, 0, vals, -1, &ow, y);
}

void asl_hessval(ASL *asl, double *y, double w, double *vals) {
  asl_hessval_ew(asl->i.Ew0, y, w, vals);
}
