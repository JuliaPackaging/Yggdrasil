#include "cv.h"
#include "fit.h"
#include "jlcxx/jlcxx.hpp"

JLCXX_MODULE
define_julia_module(jlcxx::Module& module)
{
  module.method("fit_slope_dense", &fit_slope_dense);
  module.method("fit_slope_sparse", &fit_slope_sparse);
  module.method("cv_slope_dense", &cv_slope_dense);
  module.method("cv_slope_sparse", &cv_slope_sparse);
}
