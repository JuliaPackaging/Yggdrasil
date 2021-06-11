#include "jlcxx/jlcxx.hpp"
#include <Xyce_config.h>
#include <N_CIR_GenCouplingSimulator.h>

void report_handler(const char *m, unsigned i)
{
    std::cout << m;
}

// by default Xyce aborts on an error.
// As a library we don't like that
void set_report_handler() {
    Xyce::set_report_handler(&report_handler);
}

class OutputHandler final : public Xyce::IO::ExternalOutputInterface
{
public:
    OutputHandler(std::string name,
    Xyce::IO::OutputType::OutputType type,
    std::vector<std::string> outputs)
        : requested_fieldnames(outputs), type(type), name(name) { }

    std::string getName()
    {
        return name;
    }

    Xyce::IO::OutputType::OutputType getOutputType()
    {
        return type;
    }

    void requestedOutputs(std::vector<std::string> &outputVars)
    {
        outputVars = requested_fieldnames;
    }

    void outputFieldNames(std::vector<std::string> &outputNames)
    {
        fieldnames = outputNames;
        real_data.resize(outputNames.size());
    }

    std::vector<std::string> getFieldnames() {
        return fieldnames;
    }

    std::vector<double> getRealData(unsigned int idx) {
        return real_data[idx];
    }

    void outputReal(std::vector<double> &outputData)
    {
        for(int i=0;i<outputData.size();i++) {
            real_data[i].push_back(outputData[i]);
        }
    }

    void outputComplex(std::vector<std::complex<double>> &outputData)
    {
        // TODO: how to expose std::complex to julia?
    }

    std::string name;
    Xyce::IO::OutputType::OutputType type;
    std::vector<std::string> requested_fieldnames;
    std::vector<std::string> fieldnames;
    std::vector<std::vector<double>> real_data;
};

namespace jlcxx
{
  // Needed for upcasting
  template<> struct SuperType<OutputHandler> { typedef Xyce::IO::ExternalOutputInterface type; };
}

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
    mod.add_bits<Xyce::IO::OutputType::OutputType>("OutputType", jlcxx::julia_type("CppEnum"));
    mod.set_const("DC", Xyce::IO::OutputType::OutputType::DC);
    mod.set_const("TRAN", Xyce::IO::OutputType::OutputType::TRAN);
    mod.set_const("AC", Xyce::IO::OutputType::OutputType::AC);
    mod.set_const("AC_IC", Xyce::IO::OutputType::OutputType::AC_IC);
    mod.set_const("HB_FD", Xyce::IO::OutputType::OutputType::HB_FD);
    mod.set_const("HB_TD", Xyce::IO::OutputType::OutputType::HB_TD);
    mod.set_const("HB_IC", Xyce::IO::OutputType::OutputType::HB_IC);
    mod.set_const("HB_STARTUP", Xyce::IO::OutputType::OutputType::HB_STARTUP);
    mod.set_const("DCOP", Xyce::IO::OutputType::OutputType::DCOP);
    mod.set_const("HOMOTOPY", Xyce::IO::OutputType::OutputType::HOMOTOPY);
    mod.set_const("MPDE", Xyce::IO::OutputType::OutputType::MPDE);
    mod.set_const("MPDE_IC", Xyce::IO::OutputType::OutputType::MPDE_IC);
    mod.set_const("MPDE_STARTUP", Xyce::IO::OutputType::OutputType::MPDE_STARTUP);
    mod.set_const("SENS", Xyce::IO::OutputType::OutputType::SENS);
    mod.set_const("TRANADJOINT", Xyce::IO::OutputType::OutputType::TRANADJOINT);
    mod.set_const("NOISE", Xyce::IO::OutputType::OutputType::NOISE);
    mod.set_const("SPARAM", Xyce::IO::OutputType::OutputType::SPARAM);
    mod.set_const("ES", Xyce::IO::OutputType::OutputType::ES);
    mod.set_const("PCE", Xyce::IO::OutputType::OutputType::ES);

    mod.add_bits<Xyce::Circuit::Simulator::RunStatus>("RunStatus", jlcxx::julia_type("CppEnum"));
    mod.set_const("ERROR", Xyce::Circuit::Simulator::RunStatus::ERROR);
    mod.set_const("SUCCESS", Xyce::Circuit::Simulator::RunStatus::SUCCESS);
    mod.set_const("DONE", Xyce::Circuit::Simulator::RunStatus::DONE);

    mod.add_type<Xyce::IO::ExternalOutputInterface>("ExternalOutputInterface");
    mod.add_type<OutputHandler>("OutputHandler", jlcxx::julia_base_type<Xyce::IO::ExternalOutputInterface>())
        .constructor<std::string, Xyce::IO::OutputType::OutputType, std::vector<std::string>>()
        .method("getFieldnames", &OutputHandler::getFieldnames)
        .method("getRealData", &OutputHandler::getRealData);

    mod.add_type<Xyce::Circuit::GenCouplingSimulator>("GenCouplingSimulator")
        .method("initialize", &Xyce::Circuit::GenCouplingSimulator::initialize)
        .method("addOutputInterface", &Xyce::Circuit::GenCouplingSimulator::addOutputInterface)
        .method("runSimulation", &Xyce::Circuit::GenCouplingSimulator::runSimulation);

    mod.method("set_report_handler", &set_report_handler);
}
