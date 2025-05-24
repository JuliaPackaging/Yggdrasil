#include "cv.h"
#include "helpers.h"
#include <Eigen/SparseCore>
#include <slope/cv.h>
#include <slope/slope.h>

std::tuple<double,
           int,
           int,
           jlcxx::Array<std::int64_t>,
           jlcxx::Array<double>,
           jlcxx::Array<std::int64_t>,
           jlcxx::Array<double>,
           jlcxx::Array<double>,
           jlcxx::Array<double>,
           jlcxx::Array<double>>
cv_slope_dense(jlcxx::ArrayRef<double, 2> x_in,
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
               std::int64_t n_folds,
               std::int64_t n_repeats,
               std::string metric,
               std::vector<double> q_cv,
               std::vector<double> gamma_cv,
               std::vector<std::int64_t> fold_indices)
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
  Map<VectorXd> y(y_in.data(), n);

  auto cv_config = slope::CvConfig();

  std::map<std::string, std::vector<double>> hyperparams;
  hyperparams["q"] = q_cv;
  hyperparams["gamma"] = gamma_cv;

  cv_config.hyperparams = hyperparams;
  cv_config.metric = metric;
  cv_config.predefined_folds =
    createCvFolds(fold_indices, n, n_folds, n_repeats);

  MatrixXd x = x_map;

  auto res = crossValidate(model, x, y, cv_config);

  jlcxx::Array<std::int64_t> param_name;
  jlcxx::Array<double> param_value;

  jlcxx::Array<std::int64_t> path_lengths;
  jlcxx::Array<double> alphas;
  jlcxx::Array<double> mean_scores;
  jlcxx::Array<double> std_errors;
  jlcxx::Array<double> scores;

  int n_alpha = res.results[0].alphas.size();

  for (int i = 0; i < res.results.size(); ++i) {
    auto grid_result = res.results[i];

    int path_length_i = grid_result.alphas.size();

    path_lengths.push_back(path_length_i);

    for (int k = 0; k < grid_result.score.cols(); ++k) {
      for (int j = 0; j < grid_result.score.rows(); ++j) {
        scores.push_back(grid_result.score(j, k));
      }
    }

    for (int j = 0; j < path_length_i; ++j) {
      alphas.push_back(grid_result.alphas[j]);
      mean_scores.push_back(grid_result.mean_scores[j]);
      std_errors.push_back(grid_result.std_errors[j]);
    }

    for (const auto& param : grid_result.params) {

      std::int64_t name_code = 0;

      if (param.first == "alpha")
        name_code = 0;
      else if (param.first == "q")
        name_code = 1;
      else if (param.first == "gamma")
        name_code = 2;

      if (name_code != 0) {
        param_name.push_back(name_code);
        param_value.push_back(param.second);
      }
    }
  }

  return std::make_tuple(res.best_score,
                         res.best_ind,
                         res.best_alpha_ind,
                         param_name,
                         param_value,
                         path_lengths,
                         scores,
                         alphas,
                         mean_scores,
                         std_errors);
}

std::tuple<double,
           int,
           int,
           jlcxx::Array<std::int64_t>,
           jlcxx::Array<double>,
           jlcxx::Array<std::int64_t>,
           jlcxx::Array<double>,
           jlcxx::Array<double>,
           jlcxx::Array<double>,
           jlcxx::Array<double>>
cv_slope_sparse(jlcxx::ArrayRef<std::int64_t, 1> x_colptr,
                jlcxx::ArrayRef<std::int64_t, 1> x_rowval,
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
                std::size_t path_length,
                double tol,
                std::int64_t max_it,
                double q,
                std::int64_t max_clusters,
                double dev_change_tol,
                double dev_ratio_tol,
                double alpha_min_ratio,
                std::int64_t n_folds,
                std::int64_t n_repeats,
                std::string metric,
                std::vector<double> q_cv,
                std::vector<double> gamma_cv,
                std::vector<std::int64_t> fold_indices)
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

  auto x_map = mapSparseJuliaArray(x_colptr, x_rowval, x_vals, n, p);
  Map<VectorXd> y(y_in.data(), n);

  auto cv_config = slope::CvConfig();

  std::map<std::string, std::vector<double>> hyperparams;
  hyperparams["q"] = q_cv;
  hyperparams["gamma"] = gamma_cv;

  cv_config.hyperparams = hyperparams;
  cv_config.metric = metric;
  cv_config.predefined_folds =
    createCvFolds(fold_indices, n, n_folds, n_repeats);

  SparseMatrix<double> x = x_map;

  auto res = crossValidate(model, x, y, cv_config);

  jlcxx::Array<std::int64_t> param_name;
  jlcxx::Array<double> param_value;

  jlcxx::Array<std::int64_t> path_lengths;
  jlcxx::Array<double> alphas;
  jlcxx::Array<double> mean_scores;
  jlcxx::Array<double> std_errors;
  jlcxx::Array<double> scores;

  int n_alpha = res.results[0].alphas.size();

  for (int i = 0; i < res.results.size(); ++i) {
    auto grid_result = res.results[i];

    int path_length_i = grid_result.alphas.size();

    path_lengths.push_back(path_length_i);

    for (int k = 0; k < grid_result.score.cols(); ++k) {
      for (int j = 0; j < grid_result.score.rows(); ++j) {
        scores.push_back(grid_result.score(j, k));
      }
    }

    for (int j = 0; j < path_length_i; ++j) {
      alphas.push_back(grid_result.alphas[j]);
      mean_scores.push_back(grid_result.mean_scores[j]);
      std_errors.push_back(grid_result.std_errors[j]);
    }

    for (const auto& param : grid_result.params) {

      std::int64_t name_code = 0;

      if (param.first == "alpha")
        name_code = 0;
      else if (param.first == "q")
        name_code = 1;
      else if (param.first == "gamma")
        name_code = 2;

      if (name_code != 0) {
        param_name.push_back(name_code);
        param_value.push_back(param.second);
      }
    }
  }

  return std::make_tuple(res.best_score,
                         res.best_ind,
                         res.best_alpha_ind,
                         param_name,
                         param_value,
                         path_lengths,
                         scores,
                         alphas,
                         mean_scores,
                         std_errors);
}
