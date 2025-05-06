#include "jlcxx/jlcxx.hpp"
#include <Eigen/SparseCore>
#include <slope/slope.h>

inline slope::Slope
setupModel(bool fit_intercept,
           std::string loss_type,
           std::string centering_type,
           std::string scaling_type,
           std::int64_t path_length,
           double tol,
           std::int64_t max_it,
           double q,
           std::int64_t max_clusters,
           double dev_change_tol,
           double dev_ratio_tol,
           double alpha_min_ratio)
{
  slope::Slope model;

  model.setCentering(centering_type);
  model.setAlphaMinRatio(alpha_min_ratio);
  model.setDevChangeTol(dev_change_tol);
  model.setDevRatioTol(dev_ratio_tol);
  model.setIntercept(fit_intercept);
  model.setLoss(loss_type);
  model.setMaxClusters(max_clusters);
  model.setMaxIterations(max_it);
  model.setPathLength(path_length);
  model.setQ(q);
  model.setScaling(scaling_type);
  model.setTol(tol);

  return model;
}

inline void
returnOutput(const slope::SlopePath& res,
             jlcxx::ArrayRef<double, 1> coef_vals_out,
             jlcxx::ArrayRef<std::int64_t, 1> coef_rows_out,
             jlcxx::ArrayRef<std::int64_t, 1> coef_cols_out,
             jlcxx::ArrayRef<double, 1> intercepts_out,
             jlcxx::ArrayRef<std::int64_t, 1> nnz_out,
             jlcxx::ArrayRef<double, 1> alpha_out,
             jlcxx::ArrayRef<double, 1> lambda_out)
{
  auto coefs = res.getCoefs();
  auto intercepts = res.getIntercepts();
  Eigen::ArrayXd alpha = res.getAlpha();
  Eigen::ArrayXd lambda = res.getLambda();

  for (const auto& l : lambda) {
    lambda_out.push_back(l);
  }

  int nnz = 0;

  for (int step = 0; step < coefs.size(); ++step) {
    Eigen::SparseMatrix<double> coefs_step = coefs[step];

    for (int k = 0; k < coefs_step.outerSize(); ++k) {
      for (Eigen::SparseMatrix<double>::InnerIterator it(coefs_step, k); it;
           ++it) {
        coef_vals_out.push_back(it.value());
        coef_rows_out.push_back(it.row() + 1);
        coef_cols_out.push_back(k + 1);
        nnz++;
      }
      intercepts_out.push_back(intercepts[step](k));
    }
    nnz_out.push_back(nnz);

    alpha_out.push_back(alpha[step]);
  }
}

void
fit_slope_dense(jlcxx::ArrayRef<double, 2> x_in,
                jlcxx::ArrayRef<double, 1> y_in,
                jlcxx::ArrayRef<double, 1> alpha_in,
                jlcxx::ArrayRef<double, 1> lambda_in,
                std::int64_t n,
                std::int64_t p,
                std::int64_t m,
                bool fit_intercept,
                std::string loss_type,
                std::string centering_type,
                std::string scaling_type,
                std::size_t path_length,
                double tol,
                std::int64_t max_it,
                double q,
                std::int64_t max_clusters,
                double dev_change_tol,
                double dev_ratio_tol,
                double alpha_min_ratio,
                jlcxx::ArrayRef<double, 1> coef_vals_out,
                jlcxx::ArrayRef<std::int64_t, 1> coef_rows_out,
                jlcxx::ArrayRef<std::int64_t, 1> coef_cols_out,
                jlcxx::ArrayRef<double, 1> intercepts_out,
                jlcxx::ArrayRef<std::int64_t, 1> nnz_out,
                jlcxx::ArrayRef<double, 1> alpha_out,
                jlcxx::ArrayRef<double, 1> lambda_out)
{
  using Eigen::ArrayXd;
  using Eigen::Map;
  using Eigen::MatrixXd;
  using Eigen::SparseMatrix;
  using Eigen::VectorXd;

  slope::Slope model = setupModel(fit_intercept,
                                  loss_type,
                                  centering_type,
                                  scaling_type,
                                  path_length,
                                  tol,
                                  max_it,
                                  q,
                                  max_clusters,
                                  dev_change_tol,
                                  dev_ratio_tol,
                                  alpha_min_ratio);

  Map<MatrixXd> x_map(x_in.data(), n, p);
  Map<VectorXd> y_map(y_in.data(), n);
  Map<ArrayXd> alpha_map(alpha_in.data(), alpha_in.size());
  Map<ArrayXd> lambda_map(lambda_in.data(), lambda_in.size());

  // Copy the data into Eigen matrices
  // TODO: Use Map to avoid copies
  MatrixXd x = x_map;
  MatrixXd y = y_map;

  ArrayXd alpha = alpha_map;
  ArrayXd lambda = lambda_map;

  auto res = model.path(x, y, alpha, lambda);

  returnOutput(res,
               coef_vals_out,
               coef_rows_out,
               coef_cols_out,
               intercepts_out,
               nnz_out,
               alpha_out,
               lambda_out);
}

void
fit_slope_sparse(jlcxx::ArrayRef<std::int64_t, 1> x_rows,
                 jlcxx::ArrayRef<std::int64_t, 1> x_cols,
                 jlcxx::ArrayRef<double, 1> x_vals,
                 jlcxx::ArrayRef<double, 1> y_in,
                 jlcxx::ArrayRef<double, 1> alpha_in,
                 jlcxx::ArrayRef<double, 1> lambda_in,
                 std::int64_t n,
                 std::int64_t p,
                 std::int64_t m,
                 bool fit_intercept,
                 std::string loss_type,
                 std::string centering_type,
                 std::string scaling_type,
                 std::int64_t path_length,
                 double tol,
                 std::int64_t max_it,
                 double q,
                 std::int64_t max_clusters,
                 double dev_change_tol,
                 double dev_ratio_tol,
                 double alpha_min_ratio,
                 jlcxx::ArrayRef<double, 1> coef_vals_out,
                 jlcxx::ArrayRef<std::int64_t, 1> coef_rows_out,
                 jlcxx::ArrayRef<std::int64_t, 1> coef_cols_out,
                 jlcxx::ArrayRef<double, 1> intercepts_out,
                 jlcxx::ArrayRef<std::int64_t, 1> nnz_out,
                 jlcxx::ArrayRef<double, 1> alpha_out,
                 jlcxx::ArrayRef<double, 1> lambda_out)
{
  using Eigen::ArrayXd;
  using Eigen::Map;
  using Eigen::MatrixXd;
  using Eigen::SparseMatrix;
  using Eigen::VectorXd;

  slope::Slope model = setupModel(fit_intercept,
                                  loss_type,
                                  centering_type,
                                  scaling_type,
                                  path_length,
                                  tol,
                                  max_it,
                                  q,
                                  max_clusters,
                                  dev_change_tol,
                                  dev_ratio_tol,
                                  alpha_min_ratio);

  SparseMatrix<double> x(n, p);

  std::vector<Eigen::Triplet<double>> triplet_list;

  for (int i = 0; i < x_vals.size(); ++i) {
    triplet_list.emplace_back(x_rows[i] - 1, x_cols[i] - 1, x_vals[i]);
  }

  x.setFromTriplets(triplet_list.begin(), triplet_list.end());

  Map<VectorXd> y_map(y_in.data(), n);
  MatrixXd y = y_map;

  Map<ArrayXd> alpha_map(alpha_in.data(), alpha_in.size());
  Map<ArrayXd> lambda_map(lambda_in.data(), lambda_in.size());

  ArrayXd alpha = alpha_map;
  ArrayXd lambda = lambda_map;

  auto res = model.path(x, y, alpha, lambda);

  returnOutput(res,
               coef_vals_out,
               coef_rows_out,
               coef_cols_out,
               intercepts_out,
               nnz_out,
               alpha_out,
               lambda_out);
}

JLCXX_MODULE
define_julia_module(jlcxx::Module& module)
{
  module.method("fit_slope_dense", &fit_slope_dense);
  module.method("fit_slope_sparse", &fit_slope_sparse);
}
