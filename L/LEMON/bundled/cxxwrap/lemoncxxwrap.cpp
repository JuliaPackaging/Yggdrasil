#include "jlcxx/jlcxx.hpp"

// Win32 (mingw) defines IN and OUT as macros; undefine them before pulling
// in LEMON headers that use IN/OUT as template parameter names.
#ifdef _WIN32
#  ifdef IN
#    undef IN
#  endif
#  ifdef OUT
#    undef OUT
#  endif
#endif

#include <lemon/list_graph.h>
#include <lemon/dijkstra.h>
#include <lemon/matching.h>
#include <lemon/network_simplex.h>
#include <lemon/cost_scaling.h>
#include <lemon/capacity_scaling.h>
#include <lemon/cycle_canceling.h>

#include <functional>

using namespace lemon;
using namespace std;

std::string compiledebug()
{
   return "baseline compilation works";
}

namespace jlcxx
{
  template<> struct SuperType<ListGraph::NodeIt> { typedef ListGraph::Node type; };
  template<> struct SuperType<ListGraph::EdgeIt> { typedef ListGraph::Edge type; };
  template<> struct SuperType<ListDigraph::NodeIt> { typedef ListDigraph::Node type; };
  // no appropriate factory error
  //template<> struct SuperType<ListDigraph::ArcIt> { typedef ListDigraph::Arc type; };

  // Expose both V and C as Julia type parameters for all four MCF algorithms
  template<typename V, typename C>
  struct BuildParameterList<lemon::NetworkSimplex<lemon::ListDigraph, V, C>> {
    typedef ParameterList<V, C> type;
  };
  template<typename V, typename C>
  struct BuildParameterList<lemon::CostScaling<lemon::ListDigraph, V, C>> {
    typedef ParameterList<V, C> type;
  };
  template<typename V, typename C>
  struct BuildParameterList<lemon::CapacityScaling<lemon::ListDigraph, V, C>> {
    typedef ParameterList<V, C> type;
  };
  template<typename V, typename C>
  struct BuildParameterList<lemon::CycleCanceling<lemon::ListDigraph, V, C>> {
    typedef ParameterList<V, C> type;
  };
}

// ── NodeMap ───────────────────────────────────────────────────────────────────
// Thin wrapper so we can partially apply Graph and leave Value as the
// free parameter that apply_combination iterates over.
template<typename Graph>
struct ApplyNodeMap {
  template<typename T> using apply = typename Graph::template NodeMap<T>;
};

template<typename Graph>
struct ApplyEdgeMap {
  template<typename T> using apply = typename Graph::template EdgeMap<T>;
};

template<typename Graph>
struct ApplyArcMap {
  template<typename T> using apply = typename Graph::template ArcMap<T>;
};

// NodeMap and EdgeMap wrappers for ListGraph and ListDigraph
struct WrapNodeMapListGraph {
  template<typename TypeWrapperT>
  void operator()(TypeWrapperT&& wrapped) {
    using M = typename TypeWrapperT::type;
    wrapped.template constructor<const ListGraph&>();
    wrapped.method("set", &M::set);
    wrapped.method("get", [](const M& m, const ListGraph::Node& n) { return m[n]; });
  }
};
struct WrapNodeMapListDigraph {
  template<typename TypeWrapperT>
  void operator()(TypeWrapperT&& wrapped) {
    using M = typename TypeWrapperT::type;
    wrapped.template constructor<const ListDigraph&>();
    wrapped.method("set", &M::set);
    wrapped.method("get", [](const M& m, const ListDigraph::Node& n) { return m[n]; });
  }
};
struct WrapEdgeMapListGraph {
  template<typename TypeWrapperT>
  void operator()(TypeWrapperT&& wrapped) {
    using M = typename TypeWrapperT::type;
    wrapped.template constructor<const ListGraph&>();
    wrapped.method("set", &M::set);
    wrapped.method("get", [](const M& m, const ListGraph::Edge& e) { return m[e]; });
  }
};
struct WrapArcMapListDigraph {
  template<typename TypeWrapperT>
  void operator()(TypeWrapperT&& wrapped) {
    using M = typename TypeWrapperT::type;
    wrapped.template constructor<const ListDigraph&>();
    wrapped.method("set", &M::set);
    wrapped.method("get", [](const M& m, const ListDigraph::Arc& a) { return m[a]; });
  }
};

// ── MCF algorithms ────────────────────────────────────────────────────────────
// Both value and cost types are free parameters → two-parameter apply_combination.
// We use a single ApplyAlgo adapter per algorithm template.
template<template<typename,typename,typename> class Algo>
struct ApplyAlgo {
  template<typename V, typename C>
  using apply = Algo<ListDigraph, V, C>;
};

// CostScaling and CapacityScaling have a 4th Traits parameter (with a default).
// Clang strictly requires template template arguments to match the declared
// parameter count, so we provide explicit 3-parameter alias templates that
// drop the Traits parameter and let it default.  GCC accepts the 4-parameter
// templates directly, but Clang (used for Apple targets) does not.
template<typename GR, typename V, typename C>
using CostScaling3 = lemon::CostScaling<GR, V, C>;

template<typename GR, typename V, typename C>
using CapacityScaling3 = lemon::CapacityScaling<GR, V, C>;

// One generic wrapper for all four algorithms (they share identical API).
struct WrapMCFAlgo {
  template<typename TypeWrapperT>
  void operator()(TypeWrapperT&& wrapped) {
    using Algo = typename TypeWrapperT::type;
    using V = typename Algo::Value;   // lemon exposes these
    using C = typename Algo::Cost;
    wrapped.template constructor<const ListDigraph&>();
    wrapped.method("lowerMap",  [](Algo& a, const ListDigraph::ArcMap<V>& m)  -> Algo& { return a.lowerMap(m);  });
    wrapped.method("upperMap",  [](Algo& a, const ListDigraph::ArcMap<V>& m)  -> Algo& { return a.upperMap(m);  });
    wrapped.method("costMap",   [](Algo& a, const ListDigraph::ArcMap<C>& m)  -> Algo& { return a.costMap(m);   });
    wrapped.method("supplyMap", [](Algo& a, const ListDigraph::NodeMap<V>& m) -> Algo& { return a.supplyMap(m); });
    wrapped.method("stSupply",    &Algo::stSupply);
    wrapped.method("reset",       &Algo::reset);
    wrapped.method("resetParams", &Algo::resetParams);
    wrapped.method("run",         [](Algo& a) { return static_cast<int>(a.run()); });
    wrapped.method("totalCost",   static_cast<C (Algo::*)() const>(&Algo::totalCost));
    wrapped.method("flow",        &Algo::flow);
    wrapped.method("potential",   &Algo::potential);
  }
};

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
  mod.method("compiledebug", &compiledebug);

  mod.add_type<ListGraph::Node>("ListGraphNode");
  mod.add_type<ListDigraph::Node>("ListDigraphNode");
  mod.add_type<ListGraph::Edge>("ListGraphEdge");
  mod.add_type<ListGraph::Arc>("ListGraphArc");
  mod.add_type<ListDigraph::Arc>("ListDigraphArc");

  mod.method("id", static_cast<int(*)(ListGraph::Node)>(&ListGraph::id));
  mod.method("id", static_cast<int(*)(ListGraph::Edge)>(&ListGraph::id));
  mod.method("id", static_cast<int(*)(ListGraph::Arc)>(&ListGraph::id));
  mod.method("id", static_cast<int(*)(ListDigraph::Node)>(&ListDigraph::id));
  mod.method("id", static_cast<int(*)(ListDigraph::Arc)>(&ListDigraph::id));

  mod.add_type<ListGraph>("ListGraph")
    .method("addNode"  , &ListGraph::addNode)
    .method("addEdge"  , &ListGraph::addEdge)
    .method("u", [](const ListGraph& g, const ListGraph::Edge& e) { return g.u(e); })
    .method("v", [](const ListGraph& g, const ListGraph::Edge& e) { return g.v(e); });
  mod.add_type<ListDigraph>("ListDigraph")
    .method("addNode"  , &ListDigraph::addNode)
    .method("addArc"   , &ListDigraph::addArc)
    .method("source", [](const ListDigraph& g, const ListDigraph::Arc& a) { return g.source(a); })
    .method("target", [](const ListDigraph& g, const ListDigraph::Arc& a) { return g.target(a); });

  mod.add_type<ListGraph::NodeIt>("ListGraphNodeIt", jlcxx::julia_base_type<ListGraph::Node>())
    .constructor<const ListGraph&>()
    .method("iternext", &ListGraph::NodeIt::operator++);
  mod.add_type<ListDigraph::NodeIt>("ListDigraphNodeIt", jlcxx::julia_base_type<ListDigraph::Node>())
    .constructor<const ListDigraph&>()
    .method("iternext", &ListDigraph::NodeIt::operator++);
  mod.add_type<ListGraph::EdgeIt>("ListGraphEdgeIt", jlcxx::julia_base_type<ListGraph::Edge>())
    .constructor<const ListGraph&>()
    .method("iternext", &ListGraph::EdgeIt::operator++);
  // no appropriate factory error
  //mod.add_type<ListDigraph::ArcIt>("ListDigraphArcIt", jlcxx::julia_base_type<ListDigraph::ArcIt>())
  //  .constructor<const ListDigraph&>()
  //  .method("iternext", &ListDigraph::ArcIt::operator++);

  using ValueTypes = jlcxx::ParameterList<int8_t, int16_t, int32_t, int64_t>;
  using ValueTypesNoNarrow = jlcxx::ParameterList<int32_t, int64_t>;  // safe for CapacityScaling

  // Maps
  mod.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("ListGraphNodeMap")
    .apply_combination<ApplyNodeMap<ListGraph>, ValueTypes>(WrapNodeMapListGraph());

  mod.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("ListDigraphNodeMap")
    .apply_combination<ApplyNodeMap<ListDigraph>, ValueTypes>(WrapNodeMapListDigraph());

  mod.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("ListGraphEdgeMap")
    .apply_combination<ApplyEdgeMap<ListGraph>, ValueTypes>(WrapEdgeMapListGraph());

  mod.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>>>("ListDigraphArcMap")
    .apply_combination<ApplyArcMap<ListDigraph>, ValueTypes>(WrapArcMapListDigraph());

  mod.method("ListGraphNodeFromId", [](int i) { return ListGraph::nodeFromId(i); });
  mod.method("ListGraphEdgeFromId", [](int i) { return ListGraph::edgeFromId(i); });
  mod.method("ListDigraphNodeFromId", [](int i) { return ListDigraph::nodeFromId(i); });
  mod.method("ListDigraphArcFromId", [](int i) { return ListDigraph::arcFromId(i); });

  using DijkstraInt = Dijkstra<ListDigraph, ListDigraph::ArcMap<int>>;
  using DijkstraRunS = void (DijkstraInt::*)(ListDigraph::Node);
  using DijkstraRunST = bool (DijkstraInt::*)(ListDigraph::Node, ListDigraph::Node);
  DijkstraRunS dijkstra_run_s = &DijkstraInt::run;
  DijkstraRunST dijkstra_run_st = &DijkstraInt::run;
  mod.add_type<DijkstraInt>("DijkstraListDigraphArcMapInt")
    .constructor<const ListDigraph&, const ListDigraph::ArcMap<int>&>()
    .method("run", dijkstra_run_s)
    .method("run", dijkstra_run_st)
    .method("dist", &DijkstraInt::dist)
    .method("predNode", &DijkstraInt::predNode)
    .method("predArc", &DijkstraInt::predArc)
    .method("reached", &DijkstraInt::reached);

  using MWPM = MaxWeightedPerfectMatching<ListGraph, ListGraph::EdgeMap<int>>;
  using MWPMmatchingedge_ptr = bool (MWPM::*)(const ListGraph::Edge&) const; // used to resolve the overloads of `matching`
  using MWPMmatchingnode_ptr = ListGraph::Arc (MWPM::*)(const ListGraph::Node&) const; // used to resolve the overloads of `matching`
  MWPMmatchingedge_ptr matchingedge = &MWPM::matching;
  MWPMmatchingnode_ptr matchingnode = &MWPM::matching;
  mod.add_type<MWPM>("MaxWeightedPerfectMatchingListGraphInt")
    .constructor<const ListGraph&, const ListGraph::EdgeMap<int>&>()
    .method("mate", &MWPM::mate)
    .method("run", &MWPM::run)
    .method("matchingWeight", &MWPM::matchingWeight)
    .method("matching", matchingedge)
    .method("matching", matchingnode)
    .method("dualValue", &MWPM::dualValue)
    .method("nodeValue", &MWPM::nodeValue)
    .method("blossomNum", &MWPM::blossomNum)
    .method("blossomSize", &MWPM::blossomSize)
    .method("blossomValue", &MWPM::blossomValue);

  // MCF algorithms — one add_type per algorithm, both V and C vary
  #define REGISTER_MCF_ALGO(Template, JlName, VTypes, CTypes)                      \
    mod.add_type<jlcxx::Parametric<jlcxx::TypeVar<1>, jlcxx::TypeVar<2>>>(JlName)  \
       .apply_combination<ApplyAlgo<Template>, VTypes, CTypes>(WrapMCFAlgo());

  REGISTER_MCF_ALGO(NetworkSimplex,  "NetworkSimplex",  ValueTypes,         ValueTypes)
  REGISTER_MCF_ALGO(CostScaling3,    "CostScaling",     ValueTypes,         ValueTypes)
  REGISTER_MCF_ALGO(CapacityScaling3,"CapacityScaling", ValueTypesNoNarrow, ValueTypesNoNarrow)
  REGISTER_MCF_ALGO(CycleCanceling,  "CycleCanceling",  ValueTypes,         ValueTypes)

  // ProblemType constants are the same for all algorithms — register once
  using AnyAlgo = NetworkSimplex<ListDigraph, int32_t, int32_t>;
  mod.method("ProblemTypeInfeasible", []() { return static_cast<int>(AnyAlgo::INFEASIBLE); });
  mod.method("ProblemTypeOptimal",    []() { return static_cast<int>(AnyAlgo::OPTIMAL);    });
  mod.method("ProblemTypeUnbounded",  []() { return static_cast<int>(AnyAlgo::UNBOUNDED);  });
}
