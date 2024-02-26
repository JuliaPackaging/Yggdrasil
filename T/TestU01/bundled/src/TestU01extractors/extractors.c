// Extractors written by Andreas Noack
#include "sres.h"
#include "sknuth.h"
#include "sstring.h"
#include "swalk.h"
#include "smarsa.h"
#include "snpair.h"
#include "scomp.h"
#include "sspectral.h"

void getPValBasic (sres_Basic *res, double pvals[]) {
    int i=0;
    for (i = 0; i < 11; ++i) {
        pvals[i] = res->pVal2[i];
    }
}

double getPValPoisson (sres_Poisson *res) {
    return (res->pVal2);
}

double getPValSmarsa (smarsa_Res *res) {
    return (res->Pois->pVal2);
}

void getPValSmarsa2 (smarsa_Res2 *res2, double pvals[]) {
    int i;
    for (i = 0; i < 11; ++i) {
        pvals[i] = res2->GCD->pVal2[i];
    }
}

void getPValChi2 (sres_Chi2 *res, double pvals[]) {
    int i;
    for (i = 0; i < 11; ++i) {
        pvals[i] = res->pVal2[i];
    }
}

void getPValRes1 (sknuth_Res1 *res, double pvalsChi[], double pvalsBas[]) {
    int i;
    for (i = 0; i < 11; ++i) {
        pvalsChi[i] = res->Chi->pVal2[i];
    }
    for (i = 0; i < 11; ++i) {
        pvalsBas[i] = res->Bas->pVal2[i];
    }
}

double getPValRes2 (sknuth_Res2 *res) {
    return (res->Pois->pVal2);
}

void getPValStringRes (sstring_Res *res, double pvals[]) {
    int i;
    for (i = 0; i < 11; ++i) {
        pvals[i] = res->Bas->pVal2[i];
    }
}

double getPValStringRes2 (sstring_Res2 *res, double pvals[]) {
    int i;
    for (i = 0; i < 11; ++i) {
        pvals[i] = res->Chi->pVal2[i];
    }
    return res->Disc->pVal2;
}

void getPValStringRes3 (sstring_Res3 *res, double pvalsRuns[], double pvalsBits[]) {
    int i;
    for (i = 0; i < 11; ++i) {
        pvalsRuns[i] = res->NRuns->pVal2[i];
    }
    for (i = 0; i < 11; ++i) {
        pvalsBits[i] = res->NBits->pVal2[i];
    }
}


void getPVal_Walk (swalk_Res *res, double pvalsH[], double pvalsM[], double pvalsJ[], double pvalsR[], double pvalsC[]) {
    int i;
    for (i = 0; i < 11; ++i) {
        pvalsH[i] = res->H[0]->pVal2[i];
    }
    for (i = 0; i < 11; ++i) {
        pvalsM[i] = res->M[0]->pVal2[i];
    }
    for (i = 0; i < 11; ++i) {
        pvalsJ[i] = res->J[0]->pVal2[i];
    }
    for (i = 0; i < 11; ++i) {
        pvalsR[i] = res->R[0]->pVal2[i];
    }
    for (i = 0; i < 11; ++i) {
        pvalsC[i] = res->C[0]->pVal2[i];
    }
}

void getPVal_Npairs (snpair_Res *res, double pvals[]) {
    int i;
    for (i = 0; i < 10; ++i) {
        pvals[i] = res->pVal[i];
    }
}

void getPValScomp (scomp_Res *res, double pvalsNum[], double pvalsSize[]) {
    int i;
    for (i = 0; i < 11; ++i) {
        pvalsNum[i] = res->JumpNum->pVal2[i];
    }
    for (i = 0; i < 11; ++i) {
        pvalsSize[i] = res->JumpSize->pVal2[i];
    }
}

void getPValSspectral (sspectral_Res *res, double pvals[]) {
    int i;
    for (i = 0; i < 11; ++i) {
        pvals[i] = res->Bas->pVal2[i];
    }
}
