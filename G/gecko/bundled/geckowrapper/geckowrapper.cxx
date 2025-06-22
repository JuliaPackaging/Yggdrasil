#include "jlcxx/jlcxx.hpp"
#include "jlcxx/stl.hpp"
#include "jlcxx/functions.hpp"
#include <gecko.h>
#include <gecko/graph.h>
#include <gecko/progress.h>

// Can we automate this process here in WrapIt? We are essentially emulating C++ v-table behavior manually.
class JuliaProgressWrapper final : public Gecko::Progress {
private:
    jl_value_t*    data;
    jl_function_t* fbeginorder;
    jl_function_t* fendorder;
    jl_function_t* fbeginiter;
    jl_function_t* fenditer;
    jl_function_t* fbeginphase;
    jl_function_t* fendphase;
    jl_function_t* fquit;

public:
    JuliaProgressWrapper( jl_value_t*    data_
                        , jl_function_t* fbeginorder_
                        , jl_function_t* fendorder_
                        , jl_function_t* fbeginiter_
                        , jl_function_t* fenditer_
                        , jl_function_t* fbeginphase_
                        , jl_function_t* fendphase_
                        , jl_function_t* fquit_
                    )
    : data(data_)
    , fbeginorder(fbeginorder_)
    , fendorder(fendorder_)
    , fbeginiter(fbeginiter_)
    , fenditer(fenditer_)
    , fbeginphase(fbeginphase_)
    , fendphase(fendphase_)
    , fquit(fquit_)
    {}
    void beginorder(const Gecko::Graph* graph, Gecko::Float cost) const {
        if (this->fbeginorder != nullptr) {
            jlcxx::JuliaFunction f(this->fbeginorder);
            f(this->data, graph, static_cast<Gecko::Float>(cost));
        }
    }
    void endorder(const Gecko::Graph* graph, Gecko::Float cost) const {
        if (this->fendorder != nullptr) {
            jlcxx::JuliaFunction f(this->fendorder);
            f(this->data, graph, static_cast<Gecko::Float>(cost));
        }
    }
    void beginiter(const Gecko::Graph* graph, Gecko::uint iter, Gecko::uint maxiter, Gecko::uint window) const {
        if (this->fbeginiter != nullptr) {
            jlcxx::JuliaFunction f(this->fbeginiter);
            f(this->data, graph, static_cast<Gecko::uint>(iter),  static_cast<Gecko::uint>(maxiter),  static_cast<Gecko::uint>(window));
        }
    }
    void enditer(const Gecko::Graph* graph, Gecko::Float mincost, Gecko::Float cost) const {
        if (this->fenditer != nullptr) {
            jlcxx::JuliaFunction f(this->fenditer);
            f(this->data, graph, static_cast<Gecko::Float>(mincost), static_cast<Gecko::Float>(cost));
        }
    }
    void beginphase(const Gecko::Graph* graph, std::string name) const {
        if (this->fbeginphase != nullptr) {
            jlcxx::JuliaFunction f(this->fbeginphase);
            f(this->data, graph, name);
        }
    };
    void endphase(const Gecko::Graph* graph, bool show) const {
        if (this->fendphase != nullptr) {
            jlcxx::JuliaFunction f(this->fendphase);
            f(this->data, graph, static_cast<bool>(show));
        }
    };
    bool quit() const {
        if (this->fquit != nullptr) {
            jlcxx::JuliaFunction f(this->fquit);
            return jlcxx::unbox<bool>(f(this->data));
        }
        return false;
    }
};

namespace jlcxx
{
    template<> struct IsMirroredType<Gecko::Arc> : std::false_type { };

    template<> struct SuperType<Gecko::WeightedSum> { typedef Gecko::WeightedValue type; };

    template<> struct SuperType<Gecko::FunctionalQuasiconvex> { typedef Gecko::Functional type; };
    template<> struct SuperType<Gecko::FunctionalHarmonic> { typedef Gecko::Functional type; };
    template<> struct SuperType<Gecko::FunctionalGeometric> { typedef Gecko::Functional type; };
    template<> struct SuperType<Gecko::FunctionalSMR> { typedef Gecko::Functional type; };
    template<> struct SuperType<Gecko::FunctionalArithmetic> { typedef Gecko::Functional type; };
    template<> struct SuperType<Gecko::FunctionalRMS> { typedef Gecko::Functional type; };
    template<> struct SuperType<Gecko::FunctionalMaximum> { typedef Gecko::Functional type; };

    template<> struct SuperType<JuliaProgressWrapper> { typedef Gecko::Progress type; };
}

JLCXX_MODULE define_julia_module(jlcxx::Module& gecko)
{
    auto wv_type =  gecko.add_type<Gecko::WeightedValue>("WeightedValue");
    wv_type.constructor<Gecko::Float, Gecko::Float>();

    auto ws_type = gecko.add_type<Gecko::WeightedSum>("WeightedSum", jlcxx::julia_base_type<Gecko::WeightedValue>());
    ws_type.constructor<Gecko::Float, Gecko::Float>();

    auto arc_type = gecko.add_type<Gecko::Arc>("Arc");

    auto node_type = gecko.add_type<Gecko::Node>("Node");
    node_type.constructor<Gecko::Float, Gecko::Float, Gecko::Arc::Index, Gecko::Node::Index>();

    auto progress_type =  gecko.add_type<Gecko::Progress>("Progress");
    progress_type.constructor<>();

    // Functionals for the optimization
    auto functional_type = gecko.add_type<Gecko::Functional>("Functional");
    functional_type.method("sum", [](const Gecko::Functional& a, const Gecko::WeightedSum& s)-> Gecko::WeightedValue {return a.sum(s); } );
    functional_type.method("sum", [](const Gecko::Functional* a, const Gecko::WeightedSum& s)-> Gecko::WeightedValue {return a->sum(s); } );
    functional_type.method("sum", [](const Gecko::Functional& a, const Gecko::WeightedSum& s, const Gecko::WeightedValue& t)-> Gecko::WeightedValue {return a.sum(s, t); } );
    functional_type.method("sum", [](const Gecko::Functional* a, const Gecko::WeightedSum& s, const Gecko::WeightedValue& t)-> Gecko::WeightedValue {return a->sum(s, t); } );
    functional_type.method("sum", [](const Gecko::Functional& a, const Gecko::WeightedSum& s, const Gecko::WeightedSum& t)-> Gecko::WeightedValue {return a.sum(s, t); } );
    functional_type.method("sum", [](const Gecko::Functional* a, const Gecko::WeightedSum& s, const Gecko::WeightedSum& t)-> Gecko::WeightedValue {return a->sum(s, t); } );
    functional_type.method("accumulate", [](const Gecko::Functional& a, Gecko::WeightedSum& s, const Gecko::WeightedValue& t)-> void {return a.accumulate(s, t); } );
    functional_type.method("accumulate", [](const Gecko::Functional* a, Gecko::WeightedSum& s, const Gecko::WeightedValue& t)-> void {return a->accumulate(s, t); } );
    functional_type.method("accumulate", [](const Gecko::Functional& a, Gecko::WeightedSum& s, const Gecko::WeightedSum& t)-> void {return a.accumulate(s, t); } );
    functional_type.method("accumulate", [](const Gecko::Functional* a, Gecko::WeightedSum& s, const Gecko::WeightedSum& t)-> void {return a->accumulate(s, t); } );
    functional_type.method("less", [](const Gecko::Functional& a, Gecko::WeightedSum& s, const Gecko::WeightedSum& t)-> bool {return a.less(s, t); } );
    functional_type.method("less", [](const Gecko::Functional* a, Gecko::WeightedSum& s, const Gecko::WeightedSum& t)-> bool {return a->less(s, t); } );
    functional_type.method("mean", [](const Gecko::Functional& a, Gecko::WeightedSum& s)-> Gecko::Float {return a.mean(s); } );
    functional_type.method("mean", [](const Gecko::Functional* a, Gecko::WeightedSum& s)-> Gecko::Float {return a->mean(s); } );
    functional_type.method("bond", [](const Gecko::Functional& a, Gecko::Float f, Gecko::Float l, Gecko::uint k)-> Gecko::Float {return a.bond(f, l, k); } );
    functional_type.method("bond", [](const Gecko::Functional* a, Gecko::Float f, Gecko::Float l, Gecko::uint k)-> Gecko::Float {return a->bond(f, l, k); } );
    // FIXME We need these three lines for custom functionals. However, I could not figure out how to make the wrap work, because the WeightedValue ctor requires inputs.
    // //jlcxx::stl::apply_stl<Gecko::WeightedValue>(gecko);
    // functional_type.method("optimum", [](const Gecko::Functional& a, const std::vector<Gecko::WeightedValue>& s)-> Gecko::Float {return a.optimum(s); } );
    // functional_type.method("optimum", [](const Gecko::Functional* a, const std::vector<Gecko::WeightedValue>& s)-> Gecko::Float {return a->optimum(s); } );

    gecko.add_type<Gecko::FunctionalQuasiconvex>("FunctionalQuasiconvex", jlcxx::julia_base_type<Gecko::Functional>());
    gecko.add_type<Gecko::FunctionalHarmonic>("FunctionalHarmonic", jlcxx::julia_base_type<Gecko::Functional>());
    gecko.add_type<Gecko::FunctionalGeometric>("FunctionalGeometric", jlcxx::julia_base_type<Gecko::Functional>());
    gecko.add_type<Gecko::FunctionalSMR>("FunctionalSMR", jlcxx::julia_base_type<Gecko::Functional>());
    gecko.add_type<Gecko::FunctionalArithmetic>("FunctionalArithmetic", jlcxx::julia_base_type<Gecko::Functional>());
    gecko.add_type<Gecko::FunctionalRMS>("FunctionalRMS", jlcxx::julia_base_type<Gecko::Functional>());
    gecko.add_type<Gecko::FunctionalMaximum>("FunctionalMaximum", jlcxx::julia_base_type<Gecko::Functional>());

    auto graph_type = gecko.add_type<Gecko::Graph>("Graph");
    graph_type.constructor<Gecko::uint>();
    graph_type.method("nodes", &Gecko::Graph::nodes);
    graph_type.method("edges", &Gecko::Graph::edges);
    graph_type.method("insert_node", &Gecko::Graph::insert_node);
    graph_type.method("node_begin", &Gecko::Graph::node_begin);
    graph_type.method("node_end", &Gecko::Graph::node_end);
    graph_type.method("node_degree", &Gecko::Graph::node_degree);
    graph_type.method("node_neighbors", &Gecko::Graph::node_neighbors);
    graph_type.method("insert_arc", &Gecko::Graph::insert_arc);
    graph_type.method("remove_edge", &Gecko::Graph::remove_edge);
    graph_type.method("arc_index", &Gecko::Graph::arc_index);
    graph_type.method("arc_source", &Gecko::Graph::arc_source);
    graph_type.method("arc_target", &Gecko::Graph::arc_target);
    graph_type.method("arc_weight", &Gecko::Graph::arc_weight);
    graph_type.method("order", &Gecko::Graph::order);
    graph_type.method("permutation", [](const Gecko::Graph& a)-> const std::vector<Gecko::Node::Index>& {return a.permutation(); } );
    graph_type.method("permutation", [](const Gecko::Graph* a)-> const std::vector<Gecko::Node::Index>& {return a->permutation(); } );
    graph_type.method("permutation", [](const Gecko::Graph& a, Gecko::uint rank)-> Gecko::Node::Index {return a.permutation(rank); } );
    graph_type.method("permutation", [](const Gecko::Graph* a, Gecko::uint rank)-> Gecko::Node::Index {return a->permutation(rank); } );
    graph_type.method("rank", &Gecko::Graph::rank);
    graph_type.method("cost", [](const Gecko::Graph& a)-> Gecko::Float {return a.cost(); } );
    graph_type.method("cost", [](const Gecko::Graph* a)-> Gecko::Float {return a->cost(); } );
    // Protected
    // graph_type.method("cost", [](const Gecko::Graph& a, const std::vector<Gecko::Arc::Index>& subset, Gecko::Float pos)-> Gecko::WeightedSum {return a.cost(subset, pos); } );
    // graph_type.method("cost", [](const Gecko::Graph* a, const std::vector<Gecko::Arc::Index>& subset, Gecko::Float pos)-> Gecko::WeightedSum {return a->cost(subset, pos); } );
    graph_type.method("directed", &Gecko::Graph::directed);

    progress_type.method("beginorder", [](const Gecko::Progress& a, const Gecko::Graph* s, Gecko::Float c)-> void {return a.beginorder(s, c); } );
    progress_type.method("beginorder", [](const Gecko::Progress* a, const Gecko::Graph* s, Gecko::Float c)-> void {return a->beginorder(s, c); } );
    progress_type.method("endorder", [](const Gecko::Progress& a, const Gecko::Graph* s, Gecko::Float c)-> void {return a.endorder(s, c); } );
    progress_type.method("endorder", [](const Gecko::Progress* a, const Gecko::Graph* s, Gecko::Float c)-> void {return a->endorder(s, c); } );
    progress_type.method("beginiter", [](const Gecko::Progress& a, const Gecko::Graph* s, Gecko::uint c, Gecko::uint c2, Gecko::uint c3)-> void {return a.beginiter(s, c, c2, c3); } );
    progress_type.method("beginiter", [](const Gecko::Progress* a, const Gecko::Graph* s, Gecko::uint c, Gecko::uint c2, Gecko::uint c3)-> void {return a->beginiter(s, c, c2, c3); } );
    progress_type.method("enditer", [](const Gecko::Progress& a, const Gecko::Graph* s, Gecko::Float c, Gecko::Float c2)-> void {return a.enditer(s, c, c2); } );
    progress_type.method("enditer", [](const Gecko::Progress* a, const Gecko::Graph* s, Gecko::Float c, Gecko::Float c2)-> void {return a->enditer(s, c, c2); } );
    progress_type.method("beginphase", [](const Gecko::Progress& a, const Gecko::Graph* s, std::string c)-> void {return a.beginphase(s, c); } );
    progress_type.method("beginphase", [](const Gecko::Progress* a, const Gecko::Graph* s, std::string c)-> void {return a->beginphase(s, c); } );
    progress_type.method("endphase", [](const Gecko::Progress& a, const Gecko::Graph* s, bool c)-> void {return a.endphase(s, c); } );
    progress_type.method("endphase", [](const Gecko::Progress* a, const Gecko::Graph* s, bool c)-> void {return a->endphase(s, c); } );
    progress_type.method("quit", [](const Gecko::Progress& a)-> bool {return a.quit(); } );
    progress_type.method("endorder", [](const Gecko::Progress* a)-> bool {return a->quit(); } );

    auto jlprogress_type = gecko.add_type<JuliaProgressWrapper>("JuliaProgressWrapper", jlcxx::julia_base_type<Gecko::Progress>());
    jlprogress_type.constructor<jl_value_t*, jl_function_t*, jl_function_t*, jl_function_t*, jl_function_t*, jl_function_t*, jl_function_t*, jl_function_t*>();
}
