#include <casadi/casadi.hpp>
#include <iomanip>

using namespace casadi;

int main(int argc, char **argv){
  std::string nl_filename = argv[1];
  NlpBuilder model;
  model.import_nl(nl_filename);
  Dict options;
  options["error_on_fail"] = true;
  options["print_time"] = false;
  Function solver = nlpsol("casadi", "ipopt", model, options);
  std::map<std::string, DM> input, solution;
  input["lbx"] = model.x_lb;
  input["ubx"] = model.x_ub;
  input["lbg"] = model.g_lb;
  input["ubg"] = model.g_ub;
  input["x0"] = model.x_init;
  bool is_optimal = false;
  try {
    solution = solver(input);
    is_optimal = true;
  } catch (std::exception& e) {
    is_optimal = false;
  }
  // Output .sol filename replaces .nl with .sol.
  std::ofstream solfile;
  solfile.open(nl_filename.substr(0, nl_filename.find_last_of('.'))+".sol");
  solfile << "Options" << std::endl;
  solfile << "0" << std::endl;                // number of options
  solfile << model.g_lb.size() << std::endl;  // number of constraints
  solfile << "0" << std::endl;                // number of dual solutions
  solfile << model.x_lb.size() << std::endl;  // number of variables
  if (is_optimal) {
    solfile << model.x_lb.size() << std::endl;  // number of primal solutions
    for (double xi : std::vector<double>(solution["x"])) {
      solfile << xi << std::endl;               // primal solutions
    }
    solfile << "objno 0 0" << std::endl;
  } else {
    solfile << "0" << std::endl;
    solfile << "objno 0 500" << std::endl;
  }
  solfile.close();
  return 0;
}
