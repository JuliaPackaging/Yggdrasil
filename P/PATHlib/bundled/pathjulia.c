#include <limits.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "MCP_Interface.h"

#include "Path.h"
#include "PathOptions.h"

#include "Macros.h"
#include "Output_Interface.h"
#include "Options.h"



typedef struct {
  int n;
  int nnz;

  double *z;
  double *f;

  double *lb;
  double *ub;

  char **var_name;
  char **con_name;

  int (*f_eval)(int n, double *z, double *f);
  int (*j_eval)(int n, int nnz, double *z, int *col_start, int *col_len,
              int *row, double *data);
} Problem;

static Problem problem;








static CB_FUNC(void) problem_size(void *id, int *n, int *nnz) {
  *n = problem.n;
  *nnz = problem.nnz;
  return;
}

static CB_FUNC(void) bounds(void *id, int n, double *z, double *lb, double *ub) {
  int i;
  for (i = 0; i < n; i++) {
    z[i] = problem.z[i];
    lb[i] = problem.lb[i];
    ub[i] = problem.ub[i];
  }
  return;
}

static CB_FUNC(int) function_evaluation(void *id, int n, double *z, double *f) {
  int err;
  err = problem.f_eval(n, z, f);
  return err;
}

static CB_FUNC(int) jacobian_evaluation(void *id, int n, double *z, int wantf, double *f, int *nnz, int *col_start, int *col_len, int *row, double *data) {
  int i, err = 0;

  if (wantf) {
    err += function_evaluation(id, n, z, f);
  }

  err += problem.j_eval(n, *nnz, z, col_start, col_len, row, data);

  (*nnz) = 0;
  for (i = 0; i < n; i++) {
    (*nnz) += col_len[i];
  }
  return err;
}

static CB_FUNC(void) variable_name(void *id, int variable, char *buffer, int buf_size) {
  strncpy(buffer, problem.var_name[variable-1], buf_size - 1);
  buffer[buf_size-1] = '\0';
  return;
}

static CB_FUNC(void) constraint_name(void *id, int constr, char *buffer, int buf_size) {
  strncpy(buffer, problem.con_name[constr-1], buf_size - 1);
  buffer[buf_size-1] = '\0';
  return;
}

// static MCP_Interface mcp_interface;
static MCP_Interface mcp_interface = {
      NULL,
      problem_size,
      bounds,
      function_evaluation,
      jacobian_evaluation,
      NULL, /* hessian evaluation */
      NULL, /* start */
      NULL, /* finish */
      variable_name, /* variable_name */
      constraint_name, /* constraint_name */
      NULL  /* basis */
    };


/* callback to register with PATH: output from PATH will go here */
static CB_FUNC(void) messageCB (void *data, int mode, char *buf) {
  fprintf (stdout, "%s", buf);
} /* messageCB */
static Output_Interface outputInterface = {
  NULL,
  messageCB,
  NULL
};

////////////////////////////////////////////////////////////////////////////
// Main Function to be called from Julia
////////////////////////////////////////////////////////////////////////////

int path_main( int n, int nnz,
                double *z, double *f, double *lb, double *ub,
                char **var_name, char **con_name,
                void *f_eval, void *j_eval) {


  // solve status: return value
  int status;

  // creating a Problem instance
  problem.n = n;
  problem.nnz = nnz;
  problem.z = z;
  problem.f = f;
  problem.lb = lb;
  problem.ub = ub;
  problem.var_name = var_name;
  problem.con_name = con_name;
  problem.f_eval = f_eval;
  problem.j_eval = j_eval;

  if (var_name == NULL) {
    mcp_interface.variable_name = NULL;
  } else {
    mcp_interface.variable_name = variable_name;
  }

  if (con_name == NULL) {
    mcp_interface.constraint_name = NULL;
  } else {
    mcp_interface.constraint_name = constraint_name;
  }




  // Output Interface
  #if defined(USE_OUTPUT_INTERFACE)
    Output_SetInterface(&outputInterface);
  #else
    /* N.B.: the Output_SetLog call does not work when using a DLL:
     * the IO systems of a .exe and .dll do not automatically interoperate */
    Output_SetLog(stdout);
  #endif

  // Information instance
  Information info;
  info.generate_output = Output_Log | Output_Status | Output_Listing;
  info.use_start = True;
  info.use_basics = True;

  // Options Interface
  Options_Interface *o;
  o = Options_Create();
  Path_AddOptions(o);
  Options_Default(o);
  Options_Read(o, "path.opt");
  Options_Display(o);

  // Preprocessing
  if (n == 0) {
    fprintf(stdout, "\n ** EXIT - solution found (degenerate model).\n");
    (status) = MCP_Solved;
    Options_Destroy(o);
    return status;
  }

  double dnnz;
  dnnz = MIN(1.0*nnz, 1.0*n*n);
  if (dnnz > INT_MAX) {
    fprintf(stdout, "\n ** EXIT - model too large.\n");
    (status) = MCP_Error;
    Options_Destroy(o);
    return status;
  }
  nnz = (int) dnnz;

  fprintf(stdout, "%d row/cols, %d non-zeros, %3.2f%% dense.\n\n",
          n, nnz, 100.0*nnz/(1.0*n*n));
  nnz++;




  // preparing an MCP instance and interfaces
  MCP *m;
  m = MCP_Create(n, nnz);
  MCP_SetInterface(m, &mcp_interface);
  Output_SetLog(stdout);




  // SOLVE
  status = Path_Solve(m, &info);


  // Preparing return values
  double *tempZ;
  double *tempF;
  tempZ = MCP_GetX(m);
  tempF = MCP_GetF(m);

  int i;
  for (i = 0; i < n; i++) {
    z[i] = tempZ[i];
    f[i] = tempF[i];
  }



  // destroy
  MCP_Destroy(m);
  Options_Destroy(o);

  return status;

}
