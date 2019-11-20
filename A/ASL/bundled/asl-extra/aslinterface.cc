// ===============================================================
// Generic Ampl interface to facilitate usage from other languages
// Dominique Orban
// Vancouver, April 2014.
// Montreal, February 2015.
// ===============================================================

#include "aslinterface.h"

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
  pfgh_read(ampl_file, 0);     // pfgh_read closes the file.

  return asl;
}

void asl_write_sol(ASL *asl, const char *msg, double *x, double *y) {
  write_sol_ASL(asl, msg, x, y, 0); // Do not handle Option_Info for now.
}

void asl_finalize(ASL *asl) {
  ASL_free(&asl);
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

int asl_nnzj(ASL *asl) {
  return asl->i.nzc_;
}

int asl_nnzh(ASL *asl) {
  return static_cast<int>(asl->p.Sphset(asl, 0, -1, 1, 1, 1));
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

// Objective.

void asl_varscale(ASL *asl, double *s, int *err) {
  fint ne;
  int this_nvar = asl->i.n_var_;

  for (int i = 0; i < this_nvar; i++) {
    varscale_ASL(asl, i, s[i], &ne);
    *err = (int)ne;
    if (ne) return;
  }
}

double asl_obj(ASL *asl, double *x, int *err) {
  fint ne;
  double f = asl->p.Objval(asl, 0, x, &ne);
  *err = (int)ne;
  return f;
}

void asl_grad(ASL *asl, double *x, double *g, int *err) {
  fint ne;
  asl->p.Objgrd(asl, 0, x, g, &ne);
  *err = (int)ne;
}

// Lagrangian.

void asl_lagscale(ASL *asl, double s, int *err) {
  fint ne;
  lagscale_ASL(asl, s, &ne);
  *err = (int)ne;
}

// Constraints and Jacobian.

void asl_conscale(ASL *asl, double *s, int *err) {
  fint ne;
  int this_ncon = asl->i.n_con_;

  for (int j = 0; j < this_ncon; j++) {
    conscale_ASL(asl, j, s[j], &ne);
    *err = (int)ne;
    if (ne) return;
  }
}

void asl_cons(ASL *asl, double *x, double *c, int *err) {
  fint ne;
  asl->p.Conval(asl, x, c, &ne);
  *err = (int)ne;
}

double asl_jcon(ASL *asl, double *x, int j, int *err) {
  fint ne;
  double cj = asl->p.Conival(asl, j, x, &ne);
  *err = (int)ne;
  return cj;
}

void asl_jcongrad(ASL *asl, double *x, double *g, int j, int *err) {
  fint ne;
  asl->p.Congrd(asl, j, x, g, &ne);
  *err = (int)ne;
}

size_t asl_sparse_congrad_nnz(ASL *asl, int j) {
  size_t nzgj = 0;
  for (cgrad *cg = asl->i.Cgrad_[j]; cg; cg = cg->next) nzgj++;
  return nzgj;
}

void asl_sparse_congrad(
    ASL *asl, double *x, int j, int *inds, double *vals, int *err) {
  int congrd_mode_bkup = asl->i.congrd_mode;
  asl->i.congrd_mode = 1;  // Sparse gradient mode.

  fint ne;
  asl->p.Congrd(asl, j, x, vals, &ne);
  *err = (int)ne;
  if (ne) return;

  int k = 0;
  for (cgrad *cg = asl->i.Cgrad_[j]; cg; cg = cg->next)
    inds[k++] = cg->varno;

  asl->i.congrd_mode = congrd_mode_bkup;  // Restore gradient mode.
}

// Evaluate Jacobian at x in triplet form (rows, vals, cols).
void asl_jac(ASL *asl, double *x, int *rows, int *cols, double *vals, int *err) {
  int this_ncon = asl->i.n_con_;

  fint ne;
  asl->p.Jacval(asl, x, vals, &ne);
  *err = ne;
  if (ne) return;

  // Fill in sparsity pattern.
  for (int j = 0; j < this_ncon; j++)
    for (cgrad *cg = asl->i.Cgrad_[j]; cg; cg = cg->next) {
      rows[cg->goff] = j;
      cols[cg->goff] = cg->varno;
    }
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
void asl_jacval(ASL *asl, double *x, double *vals, int *err) {
  int this_ncon = asl->i.n_con_;

  fint ne;
  asl->p.Jacval(asl, x, vals, &ne);
  *err = ne;
}

// Hessian.

void asl_hprod(ASL *asl, double *y, double *v, double *hv, double w) {
  double ow = w;
  hvpinit_ASL(asl, asl->p.ihd_limit_, 0, NULL, y);
  asl->p.Hvcomp(asl, hv, v, -1, &ow, y); // nobj=-1 so ow takes precedence.
}

void asl_hvcompd(ASL *asl, double *v, double *hv, int nobj) {
  asl->p.Hvcompd(asl, hv, v, nobj);
}

void asl_ghjvprod(ASL *asl, double *g, double *v, double *ghjv) {
  int this_ncon = asl->i.n_con_;
  int this_nvar = asl->i.n_var_;
  int this_nlc  = asl->i.nlc_;
  double *hv    = static_cast<double *>(Malloc(this_nvar * sizeof(real)));

  // Process nonlinear constraints.
  for (int j = 0 ; j < this_nlc; j++) {
    asl->p.Hvcompd(asl, hv, v, j);

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

// Return Hessian at (x,y) in triplet form (rows, vals, cols).
void asl_hess(
    ASL *asl, double *y, double w, int *rows, int *cols, double *vals) {
  double ow = w;
  asl->p.Sphes(asl, 0, vals, -1, &ow, y);

  // Fill in sparsity pattern.
  int k = 0;
  for (fint i = 0; i < asl->i.n_var_; i++) {
    for (fint j = asl->i.sputinfo_->hcolstarts[i];
         j < asl->i.sputinfo_->hcolstarts[i+1]; j++) {
      rows[k] = static_cast<int>(asl->i.sputinfo_->hrownos[j]);
      cols[k] = static_cast<int>(i);
      k++;
    }
  }
}

// Return Hessian sparsity pattern (rows, cols).
// asl->Sphset must have been called previously.
void asl_hess_structure(ASL *asl, int *rows, int *cols) {
  int k = 0;
  for (fint i = 0; i < asl->i.n_var_; i++) {
    for (fint j = asl->i.sputinfo_->hcolstarts[i];
         j < asl->i.sputinfo_->hcolstarts[i+1]; j++) {
      rows[k] = static_cast<int>(asl->i.sputinfo_->hrownos[j]);
      cols[k] = static_cast<int>(i);
      k++;
    }
  }
}

// Return Hessian at (x,y) as if in triplet form, but only fill in the values.
void asl_hessval(
    ASL *asl, double *y, double w, double *vals) {
  double ow = w;
  asl->p.Sphes(asl, 0, vals, -1, &ow, y);
}
