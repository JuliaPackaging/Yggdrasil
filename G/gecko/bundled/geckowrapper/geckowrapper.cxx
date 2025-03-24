#include "jlcxx/jlcxx.hpp"
#include <gecko.h>
#include <gecko/graph.h>

// struct JLProgress : public Progress {
//     virtual void beginorder(const Graph* /*graph*/, Float /*cost*/) const {}
//     virtual void endorder(const Graph* /*graph*/, Float /*cost*/) const {}
//     virtual void beginiter(const Graph* /*graph*/, uint /*iter*/, uint /*maxiter*/, uint /*window*/) const {}
//     virtual void enditer(const Graph* /*graph*/, Float /*mincost*/, Float /*cost*/) const {}
//     virtual void beginphase(const Graph* /*graph*/, std::string /*name*/) const {};
//     virtual void endphase(const Graph* /*graph*/, bool /*show*/) const {};
//     virtual bool quit() const { return false; }
// };

namespace jlcxx
{
    template<> struct IsMirroredType<Gecko::Arc> : std::false_type { };

    template<> struct SuperType<Gecko::FunctionalQuasiconvex> { typedef Gecko::Functional type; };
    template<> struct SuperType<Gecko::FunctionalHarmonic> { typedef Gecko::Functional type; };
    template<> struct SuperType<Gecko::FunctionalGeometric> { typedef Gecko::Functional type; };
    template<> struct SuperType<Gecko::FunctionalSMR> { typedef Gecko::Functional type; };
    template<> struct SuperType<Gecko::FunctionalArithmetic> { typedef Gecko::Functional type; };
    template<> struct SuperType<Gecko::FunctionalRMS> { typedef Gecko::Functional type; };
    template<> struct SuperType<Gecko::FunctionalMaximum> { typedef Gecko::Functional type; };
}

JLCXX_MODULE define_julia_module(jlcxx::Module& gecko)
{
    gecko.add_type<Gecko::WeightedValue>("WeightedValue");

    auto arc_type = gecko.add_type<Gecko::Arc>("Arc");

    auto node_type = gecko.add_type<Gecko::Node>("Node");
    node_type.constructor<Gecko::Float, Gecko::Float, Gecko::Arc::Index, Gecko::Node::Index>();

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
    functional_type.method("bond", [](const Gecko::Functional& a, Gecko::Float f, Gecko::Float l, uint k)-> Gecko::Float {return a.bond(f, l, k); } );
    functional_type.method("bond", [](const Gecko::Functional* a, Gecko::Float f, Gecko::Float l, uint k)-> Gecko::Float {return a->bond(f, l, k); } );
    functional_type.method("optimum", [](const Gecko::Functional& a, const std::vector<Gecko::WeightedValue>& s)-> Gecko::Float {return a.optimum(s); } );
    functional_type.method("optimum", [](const Gecko::Functional* a, const std::vector<Gecko::WeightedValue>& s)-> Gecko::Float {return a->optimum(s); } );

    gecko.add_type<Gecko::FunctionalQuasiconvex>("FunctionalQuasiconvex", jlcxx::julia_base_type<Gecko::Functional>());
    gecko.add_type<Gecko::FunctionalHarmonic>("FunctionalHarmonic", jlcxx::julia_base_type<Gecko::Functional>());
    gecko.add_type<Gecko::FunctionalGeometric>("FunctionalGeometric", jlcxx::julia_base_type<Gecko::Functional>());
    gecko.add_type<Gecko::FunctionalSMR>("FunctionalSMR", jlcxx::julia_base_type<Gecko::Functional>());
    gecko.add_type<Gecko::FunctionalArithmetic>("FunctionalArithmetic", jlcxx::julia_base_type<Gecko::Functional>());
    gecko.add_type<Gecko::FunctionalRMS>("FunctionalRMS", jlcxx::julia_base_type<Gecko::Functional>());
    gecko.add_type<Gecko::FunctionalMaximum>("FunctionalMaximum", jlcxx::julia_base_type<Gecko::Functional>());

    auto graph_type = gecko.add_type<Gecko::Graph>("Graph");
    graph_type.constructor<uint>();
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
    graph_type.method("permutation", [](const Gecko::Graph& a, uint rank)-> Gecko::Node::Index {return a.permutation(rank); } );
    graph_type.method("permutation", [](const Gecko::Graph* a, uint rank)-> Gecko::Node::Index {return a->permutation(rank); } );
    graph_type.method("rank", &Gecko::Graph::rank);
    graph_type.method("cost", [](const Gecko::Graph& a)-> Gecko::Float {return a.cost(); } );
    graph_type.method("cost", [](const Gecko::Graph* a)-> Gecko::Float {return a->cost(); } );
    // Protected
    // graph_type.method("cost", [](const Gecko::Graph& a, const std::vector<Gecko::Arc::Index>& subset, Gecko::Float pos)-> Gecko::WeightedSum {return a.cost(subset, pos); } );
    // graph_type.method("cost", [](const Gecko::Graph* a, const std::vector<Gecko::Arc::Index>& subset, Gecko::Float pos)-> Gecko::WeightedSum {return a->cost(subset, pos); } );
    graph_type.method("directed", &Gecko::Graph::directed);
}


// module GeckoWrapper
//   using CxxWrap
//   @wrapmodule(() -> joinpath("lib","libgeckowrapper"))

//   function __init__()
//     @initcxx
//   end
// end
