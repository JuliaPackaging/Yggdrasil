#include "jlcxx/jlcxx.hpp"
#include "jlcxx/array.hpp"
#include "jlcxx/functions.hpp"
#include "blocksqp_method.hpp"
#include "blocksqp_options.hpp"
#include "blocksqp_problemspec.hpp"
#include "blocksqp_matrix.hpp"
#include <limits>
#include <iostream>
#include <string>

class Problemform : public blockSQP::Problemspec{
public:
    int nnz = -1;
    Problemform(int NVARS, int NCONS){
        nVar = NVARS;
        nCon = NCONS;
        blockIdx = nullptr;
    };

    virtual ~Problemform(){
        delete[] blockIdx;
    };


    //Allocate callbacks (function pointers to global julia functions)
    void (*initialize_dense)(void *jscope, double *xi, double *lambda, double *constrJac);
    void (*evaluate_dense)(void *jscope, const double *xi, const double* lambda, double *objval, double *constr, double *gradObj, double *constrJac, double **hess, int dmode, int *info);
    void (*evaluate_simple)(void *jscope, const double *xi, double *objval, double *constr, int *info);

    void (*initialize_sparse)(void *jscope, double *xi, double *lambda, double *jacNz, int *jacIndRow, int *jacIndCol);
    void (*evaluate_sparse)(void *jscope, const double *xi, const double *lambda, double *objval, double *constr, double *gradObj, double *jacNz, int *jacIndRow, int *jacIndCol, double **hess, int dmode, int *info);

    void (*restore_continuity)(void *jscope, double *xi, int *info);


    //Pass-through pointer to julia object wrapper
    void *Julia_Scope;


    //Invoke callbacks in overridden methods
    virtual void initialize(blockSQP::Matrix &xi, blockSQP::Matrix &lambda, blockSQP::Matrix &constrJac){
        (*initialize_dense)(Julia_Scope, xi.array, lambda.array, constrJac.array);
    }


    virtual void initialize(blockSQP::Matrix &xi, blockSQP::Matrix &lambda, double *&jacNz, int *&jacIndRow, int *&jacIndCol){
        jacNz = new double[nnz];
        jacIndRow = new int[nnz];
        jacIndCol = new int[nVar + 1];
        (*initialize_sparse)(Julia_Scope, xi.array, lambda.array, jacNz, jacIndRow, jacIndCol);
    }

    virtual void evaluate(const blockSQP::Matrix &xi, const blockSQP::Matrix &lambda, double *objval, blockSQP::Matrix &constr, blockSQP::Matrix &gradObj, blockSQP::Matrix &constrJac, blockSQP::SymMatrix *&hess, int dmode, int *info){
        double **hessNz = nullptr;
        if (dmode == 3){
            hessNz = new double*[nBlocks];
            for (int i = 0; i < nBlocks; i++){
                hessNz[i] = hess[i].array;
            }
        }
        else if (dmode == 2){
            hessNz = new double*[nBlocks];
            hessNz[nBlocks - 1] = hess[nBlocks - 1].array;
        }

        (*evaluate_dense)(Julia_Scope, xi.array, lambda.array, objval, constr.array, gradObj.array, constrJac.array, hessNz, dmode, info);

        delete[] hessNz;
    }

    virtual void evaluate(const blockSQP::Matrix &xi, const blockSQP::Matrix &lambda, double *objval, blockSQP::Matrix &constr, blockSQP::Matrix &gradObj, double *&jacNz, int *&jacIndRow, int *&jacIndCol, blockSQP::SymMatrix *&hess, int dmode, int *info){
        double **hessNz = nullptr;
        if (dmode == 3){
            hessNz = new double*[nBlocks];
            for (int i = 0; i < nBlocks; i++){
                hessNz[i] = hess[i].array;
            }
        }
        else if (dmode == 2){
            hessNz = new double*[nBlocks];
            hessNz[nBlocks - 1] = hess[nBlocks - 1].array;
        }

        (*evaluate_sparse)(Julia_Scope, xi.array, lambda.array, objval, constr.array, gradObj.array, jacNz, jacIndRow, jacIndCol, hessNz, dmode, info);

        delete[] hessNz;
    }

    virtual void evaluate(const blockSQP::Matrix &xi, double *objval, blockSQP::Matrix &constr, int *info){
        (*evaluate_simple)(Julia_Scope, xi.array, objval, constr.array, info);
    }


    //Optional Methods
    virtual void reduceConstrVio(blockSQP::Matrix &xi, int *info){
        if (restore_continuity != nullptr){
            (*restore_continuity)(Julia_Scope, xi.array, info);
        }
    };


    //Interface methods
    void set_bounds(jlcxx::ArrayRef<double, 1> LBV, jlcxx::ArrayRef<double, 1> UBV,
                    jlcxx::ArrayRef<double, 1> LBC, jlcxx::ArrayRef<double, 1> UBC,
                    double LBO, double UBO){
        objLo = LBO;
        objUp = UBO;

        bl.Dimension(nVar + nCon);
        bu.Dimension(nVar + nCon);
        
        for (int i = 0; i < nVar; i++){
            bl(i) = LBV[i];
            bu(i) = UBV[i];
        }
        for (int i = 0; i < nCon; i++){
            bl(nVar + i) = LBC[i];
            bu(nVar + i) = UBC[i];
        }

        return;
    }

    void set_blockIdx(jlcxx::ArrayRef<int,1> BIDX){
        nBlocks = BIDX.size() - 1;
        blockIdx = new int[nBlocks + 1];

        for (int i = 0; i < nBlocks + 1; i++){
            blockIdx[i] = BIDX[i];
        }
    }


    void set_scope(void *JSCOPE){
        Julia_Scope = JSCOPE;
    }

    //Callback setters
    void set_dense_init(void (*INIT_DENSE)(void* jscope, double* xi, double* lambda, double* constrJac)){
        initialize_dense = INIT_DENSE;
    }

    void set_dense_eval(void (*EVAL_DENSE)(void *jscope, const double *xi, const double* lambda, double *objval, double *constr, double *gradObj, double *constrJac, double **hess, int dmode, int *info)){
        evaluate_dense = EVAL_DENSE;
    }

    void set_simple_eval(void (*EVAL_SIMPLE)(void *jscope, const double *xi, double *objval, double *constr, int *info)){
        evaluate_simple = EVAL_SIMPLE;
    }

    void set_sparse_init(void (*INIT_SPARSE)(void *jscope, double *xi, double *lambda, double *jacNz, int *jacIndRow, int *jacIndCol)){
        initialize_sparse = INIT_SPARSE;
    }

    void set_sparse_eval(void (*EVAL_SPARSE)(void *jscope, const double *xi, const double *lambda, double *objval, double *constr, double *gradObj, double *jacNz, int *jacIndRow, int *jacIndCol, double **hess, int dmode, int *info)){
        evaluate_sparse = EVAL_SPARSE;
    }

    void set_continuity_restoration(void (*REST_CONT)(void *jscope, double *xi, int *info)){
        restore_continuity = REST_CONT;
    }

};


namespace jlcxx{
    template<> struct SuperType<Problemform>{typedef blockSQP::Problemspec type;};
}


JLCXX_MODULE define_julia_module(jlcxx::Module& mod){

mod.add_type<blockSQP::SQPoptions>("SQPoptions")
    .constructor<>()
    .method("get_maxItQP", [](blockSQP::SQPoptions &opts){return opts.maxItQP;})
    .method("set_printLevel", [](blockSQP::SQPoptions &opts, int val){opts.printLevel = val;})
    .method("set_printColor", [](blockSQP::SQPoptions &opts, int val){opts.printColor = val;})
    .method("set_debugLevel", [](blockSQP::SQPoptions &opts, int val){opts.debugLevel = val;})
    .method("set_eps", [](blockSQP::SQPoptions &opts, double val){opts.eps = val;})
    .method("set_inf", [](blockSQP::SQPoptions &opts, double val){opts.inf = val;})
    .method("set_opttol", [](blockSQP::SQPoptions &opts, double val){opts.opttol = val;})
    .method("set_nlinfeastol", [](blockSQP::SQPoptions &opts, double val){opts.nlinfeastol = val;})
    .method("set_sparseQP", [](blockSQP::SQPoptions &opts, int val){opts.sparseQP = val;})
    .method("set_globalization", [](blockSQP::SQPoptions &opts, int val){opts.globalization = val;})
    .method("set_restoreFeas", [](blockSQP::SQPoptions &opts, int val){opts.restoreFeas = val;})
    .method("set_maxLineSearch", [](blockSQP::SQPoptions &opts, int val){opts.maxLineSearch = val;})
    .method("set_maxConsecReducedSteps", [](blockSQP::SQPoptions &opts, int val){opts.maxConsecReducedSteps = val;})
    .method("set_maxConsecSkippedUpdates", [](blockSQP::SQPoptions &opts, int val){opts.maxConsecSkippedUpdates = val;})
    .method("set_maxItQP", [](blockSQP::SQPoptions &opts, int val){opts.maxItQP = val;})
    .method("set_blockHess", [](blockSQP::SQPoptions &opts, int val){opts.blockHess = val;})
    .method("set_hessScaling", [](blockSQP::SQPoptions &opts, int val){opts.hessScaling = val;})
    .method("set_fallbackScaling", [](blockSQP::SQPoptions &opts, int val){opts.fallbackScaling = val;})
    .method("set_maxTimeQP", [](blockSQP::SQPoptions &opts, double val){opts.maxTimeQP = val;})
    .method("set_iniHessDiag", [](blockSQP::SQPoptions &opts, double val){opts.iniHessDiag = val;})
    .method("set_colEps", [](blockSQP::SQPoptions &opts, double val){opts.colEps = val;})
    .method("set_colTau1", [](blockSQP::SQPoptions &opts, double val){opts.colTau1 = val;})
    .method("set_colTau2", [](blockSQP::SQPoptions &opts, double val){opts.colTau2 = val;})
    .method("set_hessDamp", [](blockSQP::SQPoptions &opts, int val){opts.hessDamp = val;})
    .method("set_hessDampFac", [](blockSQP::SQPoptions &opts, double val){opts.hessDampFac = val;})
    .method("set_hessUpdate", [](blockSQP::SQPoptions &opts, int val){opts.hessUpdate = val;})
    .method("set_fallbackUpdate", [](blockSQP::SQPoptions &opts, int val){opts.fallbackUpdate = val;})
    .method("set_hessLimMem", [](blockSQP::SQPoptions &opts, int val){opts.hessLimMem = val;})
    .method("set_hessMemsize", [](blockSQP::SQPoptions &opts, int val){opts.hessMemsize = val;})
    .method("set_whichSecondDerv", [](blockSQP::SQPoptions &opts, int val){opts.whichSecondDerv = val;})
    .method("set_skipFirstGlobalization", [](blockSQP::SQPoptions &opts, int val){opts.skipFirstGlobalization = val;})
    .method("set_convStrategy", [](blockSQP::SQPoptions &opts, int val){opts.convStrategy = val;})
    .method("set_maxConvQP", [](blockSQP::SQPoptions &opts, int val){opts.maxConvQP = val;})
    .method("set_maxSOCiter", [](blockSQP::SQPoptions &opts, int val){opts.maxSOCiter = val;})
    ;

mod.add_type<blockSQP::SQPstats>("SQPstats")
    .constructor<char*>()
    .method("get_pathstr", [](blockSQP::SQPstats S){return std::string(S.outpath);})
    ;

mod.add_type<blockSQP::Problemspec>("Problemspec");

mod.add_type<Problemform>("Problemform", jlcxx::julia_base_type<blockSQP::Problemspec>())
    .constructor<int, int>()
    .method("set_bounds", &Problemform::set_bounds)
    .method("set_blockIdx", &Problemform::set_blockIdx)
    .method("set_nnz", [](Problemform &P, int NNZ){P.nnz = NNZ; return;})
    .method("set_dense_init", &Problemform::set_dense_init)
    .method("set_dense_eval", &Problemform::set_dense_eval)
    .method("set_simple_eval", &Problemform::set_simple_eval)
    .method("set_sparse_init", &Problemform::set_sparse_init)
    .method("set_sparse_eval", &Problemform::set_sparse_eval)
    .method("set_continuity_restoration", &Problemform::set_continuity_restoration)
    .method("set_scope", &Problemform::set_scope)
    ;

mod.add_type<blockSQP::SQPiterate>("SQPiterate");

mod.add_type<blockSQP::SQPmethod>("SQPmethod")
    .constructor<blockSQP::Problemspec*, blockSQP::SQPoptions*, blockSQP::SQPstats*>()
    .method("cpp_init", &blockSQP::SQPmethod::init)
    .method("cpp_run", &blockSQP::SQPmethod::run)
    .method("cpp_finish", &blockSQP::SQPmethod::finish)
    .method("get_primal", [](blockSQP::SQPmethod &optimizer){return optimizer.vars->xi.array;})
    .method("get_dual", [](blockSQP::SQPmethod &optimizer){return optimizer.vars->lambda.array;})
    ;



mod.add_type<blockSQP::Matrix>("BSQP_Matrix")
    .constructor<>()
    .constructor<int, int>()
    .method("size_1", [](blockSQP::Matrix &M){return M.m;})
    .method("size_2", [](blockSQP::Matrix &M){return M.n;})
    .method("release!", [](blockSQP::Matrix &M){
        double *ptr = M.array;
        M.array = nullptr;
        M.m = 0;
        M.n = 0;
        return ptr;
    })
    .method("show_ptr", [](blockSQP::Matrix &M){return M.array;})
;


mod.add_type<blockSQP::SymMatrix>("SymMatrix")//, jlcxx::julia_base_type<blockSQP::Matrix>())
    .constructor<>()
    .method("size_1", [](blockSQP::SymMatrix &M){return M.m;})
    .method("release!", [](blockSQP::SymMatrix &M){
        double *ptr = M.array;
        M.array = nullptr;
        M.m = 0;
        return ptr;
    })
    .method("show_ptr", [](blockSQP::SymMatrix &M){return M.array;})
    .method("set_size!", [](blockSQP::SymMatrix &M, int dim){M.Dimension(dim);})
;

mod.method("show_ptr", [](blockSQP::SymMatrix *M){return M->array;});
mod.method("set_size!", [](blockSQP::SymMatrix *M, int dim){M->Dimension(dim);});
mod.method("size_1", [](blockSQP::SymMatrix *M){return M->m;});
}

