#pragma once

#include "jlcxx/jlcxx.hpp"
#include <Eigen/SparseCore>
#include <slope/slope.h>

Eigen::SparseMatrix<double, Eigen::ColMajor, int>
mapSparseJuliaArray(jlcxx::ArrayRef<std::int64_t, 1> x_colptr,
                    jlcxx::ArrayRef<std::int64_t, 1> x_rowval,
                    jlcxx::ArrayRef<double, 1> x_vals,
                    std::int64_t n,
                    std::int64_t p);

slope::Slope
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
           double alpha_min_ratio);

void
returnOutput(const slope::SlopePath& res,
             jlcxx::ArrayRef<double, 1> coef_vals_out,
             jlcxx::ArrayRef<std::int64_t, 1> coef_rows_out,
             jlcxx::ArrayRef<std::int64_t, 1> coef_cols_out,
             jlcxx::ArrayRef<double, 1> intercepts_out,
             jlcxx::ArrayRef<std::int64_t, 1> nnz_out,
             jlcxx::ArrayRef<double, 1> alpha_out,
             jlcxx::ArrayRef<double, 1> lambda_out);

std::vector<std::vector<std::vector<int>>>
createCvFolds(const std::vector<std::int64_t>& fold_indices, 
              std::int64_t n,
              std::int64_t n_folds,
              std::int64_t n_repeats);

