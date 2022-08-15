using BinaryBuilder

# LAPACK mirrors the OpenBLAS build, whereas LAPACK32 mirrors the OpenBLAS32 build.

version = v"3.10.0"

# Collection of sources required to build lapack
sources = [
    GitSource("https://github.com/Reference-LAPACK/lapack-release",
              "aa631b4b4bd13f6ae2dbab9ae9da209e1e05b0fc"),
]

# Bash recipe for building across all platforms

function lapack_script(;lapack32::Bool=false)
    script = """
    LAPACK32=$(lapack32)
    """

    script *= raw"""
    cd $WORKSPACE/srcdir/lapack*
    FFLAGS=(-cpp -ffixed-line-length-none -DUSE_ISNAN)
    if [[ ${nbits} == 64 ]] && [[ "${LAPACK32}" != "true" ]]; then
        FFLAGS="${FFLAGS} -fdefault-integer-8"
    fi

    if [[ ${nbits} == 64 ]] && [[ "${LAPACK32}" != "true" ]]; then
      syms=(CAXPBY CAXPY CBBCSD CBDSQR
      CCOPY CDOTC CDOTU CGBBRD CGBCON CGBEQU CGBEQUB CGBMV CGBRFS
      CGBSV CGBSVX CGBTF2 CGBTRF CGBTRS CGEADD CGEBAK CGEBAL CGEBD2
      CGEBRD CGECON CGEEQU CGEEQUB CGEES CGEESX CGEEV CGEEVX CGEHD2
      CGEHRD CGEJSV CGELQ2 CGELQ CGELQF CGELQT3 CGELQT CGELS CGELSD
      CGELSS CGELSY CGEMLQ CGEMLQT CGEMM3M CGEMM CGEMQR CGEMQRT CGEMV
      CGEQL2 CGEQLF CGEQP3 CGEQR2 CGEQR2P CGEQR CGEQRF CGEQRFP CGEQRT2
      CGEQRT3 CGEQRT CGERC CGERFS CGERQ2 CGERQF CGERU CGESC2 CGESDD
      CGESV CGESVD CGESVDQ CGESVDX CGESVJ CGESVX CGETC2 CGETF2 CGETRF2
      CGETRF CGETRI CGETRS CGETSLS CGGBAK CGGBAL CGGES3 CGGES CGGESX
      CGGEV3 CGGEV CGGEVX CGGGLM CGGHD3 CGGHRD CGGLSE CGGQRF CGGRQF
      CGGSVD3 CGGSVP3 CGSVJ0 CGSVJ1 CGTCON CGTRFS CGTSV CGTSVX CGTTRF
      CGTTRS CGTTS2 CHB2STKERNELS CHBEV CHBEV2STAGE CHBEVD
      CHBEVD2STAGE CHBEVX CHBEVX2STAGE CHBGST CHBGV CHBGVD CHBGVX
      CHBMV CHBTRD CHECON CHECON3 CHECONROOK CHEEQUB CHEEV CHEEV2STAGE
      CHEEVD CHEEVD2STAGE CHEEVR CHEEVR2STAGE CHEEVX CHEEVX2STAGE
      CHEGS2 CHEGST CHEGV CHEGV2STAGE CHEGVD CHEGVX CHEMM CHEMV CHER2
      CHER2K CHER CHERFS CHERK CHESV CHESVAA CHESVAA2STAGE CHESVRK
      CHESVROOK CHESVX CHESWAPR CHETD2 CHETF2 CHETF2RK CHETF2ROOK
      CHETRD CHETRD2STAGE CHETRDHB2ST CHETRDHE2HB CHETRF CHETRFAA
      CHETRFAA2STAGE CHETRFRK CHETRFROOK CHETRI2 CHETRI2X CHETRI
      CHETRI3 CHETRI3X CHETRIROOK CHETRS2 CHETRS CHETRS3 CHETRSAA
      CHETRSAA2STAGE CHETRSROOK CHFRK CHGEQZ CHLATRANSTYPE CHPCON
      CHPEV CHPEVD CHPEVX CHPGST CHPGV CHPGVD CHPGVX CHPMV CHPR2 CHPR
      CHPRFS CHPSV CHPSVX CHPTRD CHPTRF CHPTRI CHPTRS CHSEIN CHSEQR
      CIMATCOPY CLABRD CLACGV CLACN2 CLACON CLACP2 CLACPY CLACRM
      CLACRT CLADIV CLAED0 CLAED7 CLAED8 CLAEIN CLAESY CLAEV2 CLAG2Z
      CLAGGE CLAGHE CLAGS2 CLAGSY CLAGTM CLAHEF CLAHEFAA CLAHEFRK
      CLAHEFROOK CLAHILB CLAHQR CLAHR2 CLAIC1 CLAKF2 CLALS0 CLALSA
      CLALSD CLAMSWLQ CLAMTSQR CLANGB CLANGE CLANGT CLANHB CLANHE
      CLANHF CLANHP CLANHS CLANHT CLANSB CLANSP CLANSY CLANTB CLANTP
      CLANTR CLAPLL CLAPMR CLAPMT CLAQGB CLAQGE CLAQHB CLAQHE CLAQHP
      CLAQP2 CLAQPS CLAQR0 CLAQR1 CLAQR2 CLAQR3 CLAQR4 CLAQR5 CLAQSB
      CLAQSP CLAQSY CLAR1V CLAR2V CLARCM CLARF CLARFB CLARFG CLARFGP
      CLARFT CLARFX CLARFY CLARGE CLARGV CLARND CLARNV CLAROR CLAROT
      CLARRV CLARTG CLARTV CLARZ CLARZB CLARZT CLASCL CLASET CLASR
      CLASSQ CLASWLQ CLASWP CLASYF CLASYFAA CLASYFRK CLASYFROOK CLATBS
      CLATDF CLATM1 CLATM2 CLATM3 CLATM5 CLATM6 CLATME CLATMR CLATMS
      CLATMT CLATPS CLATRD CLATRS CLATRZ CLATSQR CLAUNHRCOLGETRFNP2
      CLAUNHRCOLGETRFNP CLAUU2 CLAUUM COMATCOPY CPBCON CPBEQU CPBRFS
      CPBSTF CPBSV CPBSVX CPBTF2 CPBTRF CPBTRS CPFTRF CPFTRI CPFTRS
      CPOCON CPOEQU CPOEQUB CPORFS CPOSV CPOSVX CPOTF2 CPOTRF2 CPOTRF
      CPOTRI CPOTRS CPPCON CPPEQU CPPRFS CPPSV CPPSVX CPPTRF CPPTRI
      CPPTRS CPSTF2 CPSTRF CPTCON CPTEQR CPTRFS CPTSV CPTSVX CPTTRF
      CPTTRS CPTTS2 CROT CROTG CSBMV CSCAL CSPCON CSPMV CSPR2 CSPR
      CSPRFS CSPSV CSPSVX CSPTRF CSPTRI CSPTRS CSROT CSRSCL CSSCAL
      CSTEDC CSTEGR CSTEIN CSTEMR CSTEQR CSWAP CSYCON CSYCON3
      CSYCONROOK CSYCONV CSYCONVF CSYCONVFROOK CSYEQUB CSYMM CSYMV
      CSYR2 CSYR2K CSYR CSYRFS CSYRK CSYSV CSYSVAA CSYSVAA2STAGE
      CSYSVRK CSYSVROOK CSYSVX CSYSWAPR CSYTF2 CSYTF2RK CSYTF2ROOK
      CSYTRF CSYTRFAA CSYTRFAA2STAGE CSYTRFRK CSYTRFROOK CSYTRI2
      CSYTRI2X CSYTRI CSYTRI3 CSYTRI3X CSYTRIROOK CSYTRS2 CSYTRS
      CSYTRS3 CSYTRSAA CSYTRSAA2STAGE CSYTRSROOK CTBCON CTBMV CTBRFS
      CTBSV CTBTRS CTFSM CTFTRI CTFTTP CTFTTR CTGEVC CTGEX2 CTGEXC
      CTGSEN CTGSJA CTGSNA CTGSY2 CTGSYL CTPCON CTPLQT2 CTPLQT CTPMLQT
      CTPMQRT CTPMV CTPQRT2 CTPQRT CTPRFB CTPRFS CTPSV CTPTRI CTPTRS
      CTPTTF CTPTTR CTRCON CTREVC3 CTREVC CTREXC CTRMM CTRMV CTRRFS
      CTRSEN CTRSM CTRSNA CTRSV CTRSYL CTRTI2 CTRTRI CTRTRS CTRTTF
      CTRTTP CTZRZF CUNBDB1 CUNBDB2 CUNBDB3 CUNBDB4 CUNBDB5 CUNBDB6
      CUNBDB CUNCSD2BY1 CUNCSD CUNG2L CUNG2R CUNGBR CUNGHR CUNGL2
      CUNGLQ CUNGQL CUNGQR CUNGR2 CUNGRQ CUNGTR CUNGTSQR CUNHRCOL
      CUNM22 CUNM2L CUNM2R CUNMBR CUNMHR CUNML2 CUNMLQ CUNMQL CUNMQR
      CUNMR2 CUNMR3 CUNMRQ CUNMRZ CUNMTR CUPGTR CUPMTR DAMAX DAMIN
      DASUM DAXPBY DAXPY DBBCSD DBDSDC DBDSQR DBDSVDX DCABS1 DCOMBSSQ
      DCOPY DDISNA DDOT DGBBRD DGBCON DGBEQU DGBEQUB DGBMV DGBRFS
      DGBSV DGBSVX DGBTF2 DGBTRF DGBTRS DGEADD DGEBAK DGEBAL DGEBD2
      DGEBRD DGECON DGEEQU DGEEQUB DGEES DGEESX DGEEV DGEEVX DGEHD2
      DGEHRD DGEJSV DGELQ2 DGELQ DGELQF DGELQT3 DGELQT DGELS DGELSD
      DGELSS DGELSY DGEMLQ DGEMLQT DGEMM DGEMQR DGEMQRT DGEMV DGEQL2
      DGEQLF DGEQP3 DGEQR2 DGEQR2P DGEQR DGEQRF DGEQRFP DGEQRT2
      DGEQRT3 DGEQRT DGER DGERFS DGERQ2 DGERQF DGESC2 DGESDD DGESV
      DGESVD DGESVDQ DGESVDX DGESVJ DGESVX DGETC2 DGETF2 DGETRF2
      DGETRF DGETRI DGETRS DGETSLS DGGBAK DGGBAL DGGES3 DGGES DGGESX
      DGGEV3 DGGEV DGGEVX DGGGLM DGGHD3 DGGHRD DGGLSE DGGQRF DGGRQF
      DGGSVD3 DGGSVP3 DGSVJ0 DGSVJ1 DGTCON DGTRFS DGTSV DGTSVX DGTTRF
      DGTTRS DGTTS2 DHGEQZ DHSEIN DHSEQR DIMATCOPY DISNAN DLABAD
      DLABRD DLACN2 DLACON DLACPY DLADIV1 DLADIV2 DLADIV DLAE2 DLAEBZ
      DLAED0 DLAED1 DLAED2 DLAED3 DLAED4 DLAED5 DLAED6 DLAED7 DLAED8
      DLAED9 DLAEDA DLAEIN DLAEV2 DLAEXC DLAG2 DLAG2S DLAGGE DLAGS2
      DLAGSY DLAGTF DLAGTM DLAGTS DLAGV2 DLAHILB DLAHQR DLAHR2 DLAIC1
      DLAISNAN DLAKF2 DLALN2 DLALS0 DLALSA DLALSD DLAMC3 DLAMCH DLAMRG
      DLAMSWLQ DLAMTSQR DLANEG DLANGB DLANGE DLANGT DLANHS DLANSB
      DLANSF DLANSP DLANST DLANSY DLANTB DLANTP DLANTR DLANV2
      DLAORHRCOLGETRFNP2 DLAORHRCOLGETRFNP DLAPLL DLAPMR DLAPMT DLAPY2
      DLAPY3 DLAQGB DLAQGE DLAQP2 DLAQPS DLAQR0 DLAQR1 DLAQR2 DLAQR3
      DLAQR4 DLAQR5 DLAQSB DLAQSP DLAQSY DLAQTR DLAR1V DLAR2V DLARAN
      DLARF DLARFB DLARFG DLARFGP DLARFT DLARFX DLARFY DLARGE DLARGV
      DLARND DLARNV DLAROR DLAROT DLARRA DLARRB DLARRC DLARRD DLARRE
      DLARRF DLARRJ DLARRK DLARRR DLARRV DLARTG DLARTGP DLARTGS DLARTV
      DLARUV DLARZ DLARZB DLARZT DLAS2 DLASCL DLASD0 DLASD1 DLASD2
      DLASD3 DLASD4 DLASD5 DLASD6 DLASD7 DLASD8 DLASDA DLASDQ DLASDT
      DLASET DLASQ1 DLASQ2 DLASQ3 DLASQ4 DLASQ5 DLASQ6 DLASR DLASRT
      DLASSQ DLASV2 DLASWLQ DLASWP DLASY2 DLASYF DLASYFAA DLASYFRK
      DLASYFROOK DLAT2S DLATBS DLATDF DLATM1 DLATM2 DLATM3 DLATM5
      DLATM6 DLATM7 DLATME DLATMR DLATMS DLATMT DLATPS DLATRD DLATRS
      DLATRZ DLATSQR DLAUU2 DLAUUM DMAX DMIN DNRM2 DOMATCOPY DOPGTR
      DOPMTR DORBDB1 DORBDB2 DORBDB3 DORBDB4 DORBDB5 DORBDB6 DORBDB
      DORCSD2BY1 DORCSD DORG2L DORG2R DORGBR DORGHR DORGL2 DORGLQ
      DORGQL DORGQR DORGR2 DORGRQ DORGTR DORGTSQR DORHRCOL DORM22
      DORM2L DORM2R DORMBR DORMHR DORML2 DORMLQ DORMQL DORMQR DORMR2
      DORMR3 DORMRQ DORMRZ DORMTR DPBCON DPBEQU DPBRFS DPBSTF DPBSV
      DPBSVX DPBTF2 DPBTRF DPBTRS DPFTRF DPFTRI DPFTRS DPOCON DPOEQU
      DPOEQUB DPORFS DPOSV DPOSVX DPOTF2 DPOTRF2 DPOTRF DPOTRI DPOTRS
      DPPCON DPPEQU DPPRFS DPPSV DPPSVX DPPTRF DPPTRI DPPTRS DPSTF2
      DPSTRF DPTCON DPTEQR DPTRFS DPTSV DPTSVX DPTTRF DPTTRS DPTTS2
      DROT DROTG DROTM DROTMG DRSCL DSB2STKERNELS DSBEV DSBEV2STAGE
      DSBEVD DSBEVD2STAGE DSBEVX DSBEVX2STAGE DSBGST DSBGV DSBGVD
      DSBGVX DSBMV DSBTRD DSCAL DSDOT DSECND DSFRK DSGESV DSPCON DSPEV
      DSPEVD DSPEVX DSPGST DSPGV DSPGVD DSPGVX DSPMV DSPOSV DSPR2 DSPR
      DSPRFS DSPSV DSPSVX DSPTRD DSPTRF DSPTRI DSPTRS DSTEBZ DSTEDC
      DSTEGR DSTEIN DSTEMR DSTEQR DSTERF DSTEV DSTEVD DSTEVR DSTEVX
      DSUM DSWAP DSYCON DSYCON3 DSYCONROOK DSYCONV DSYCONVF
      DSYCONVFROOK DSYEQUB DSYEV DSYEV2STAGE DSYEVD DSYEVD2STAGE
      DSYEVR DSYEVR2STAGE DSYEVX DSYEVX2STAGE DSYGS2 DSYGST DSYGV
      DSYGV2STAGE DSYGVD DSYGVX DSYMM DSYMV DSYR2 DSYR2K DSYR DSYRFS
      DSYRK DSYSV DSYSVAA DSYSVAA2STAGE DSYSVRK DSYSVROOK DSYSVX
      DSYSWAPR DSYTD2 DSYTF2 DSYTF2RK DSYTF2ROOK DSYTRD DSYTRD2STAGE
      DSYTRDSB2ST DSYTRDSY2SB DSYTRF DSYTRFAA DSYTRFAA2STAGE DSYTRFRK
      DSYTRFROOK DSYTRI2 DSYTRI2X DSYTRI DSYTRI3 DSYTRI3X DSYTRIROOK
      DSYTRS2 DSYTRS DSYTRS3 DSYTRSAA DSYTRSAA2STAGE DSYTRSROOK DTBCON
      DTBMV DTBRFS DTBSV DTBTRS DTFSM DTFTRI DTFTTP DTFTTR DTGEVC
      DTGEX2 DTGEXC DTGSEN DTGSJA DTGSNA DTGSY2 DTGSYL DTPCON DTPLQT2
      DTPLQT DTPMLQT DTPMQRT DTPMV DTPQRT2 DTPQRT DTPRFB DTPRFS DTPSV
      DTPTRI DTPTRS DTPTTF DTPTTR DTRCON DTREVC3 DTREVC DTREXC DTRMM
      DTRMV DTRRFS DTRSEN DTRSM DTRSNA DTRSV DTRSYL DTRTI2 DTRTRI
      DTRTRS DTRTTF DTRTTP DTZRZF DZAMAX DZAMIN DZASUM DZNRM2 DZSUM1
      DZSUM GOTOSETNUMTHREADS ICAMAX ICAMIN ICMAX1 IDAMAX IDAMIN IDMAX
      IDMIN IEEECK ILACLC ILACLR ILADIAG ILADLC ILADLR ILAENV2STAGE
      ILAENV ILAPREC ILASLC ILASLR ILATRANS ILAUPLO ILAVER ILAZLC
      ILAZLR IPARAM2STAGE IPARMQ ISAMAX ISAMIN ISMAX ISMIN IZAMAX
      IZAMIN IZMAX1 LSAME LSAMEN OPENBLASGETCONFIG OPENBLASGETCORENAME
      OPENBLASGETNUMPROCS OPENBLASGETNUMPROCS OPENBLASGETNUMTHREADS
      OPENBLASGETNUMTHREADS OPENBLASGETPARALLEL OPENBLASGETPARALLEL
      OPENBLASSETNUMTHREADS OPENBLASSETNUMTHREADS SAMAX SAMIN SASUM
      SAXPBY SAXPY SBBCSD SBDSDC SBDSQR SBDSVDX SCABS1 SCAMAX SCAMIN
      SCASUM SCNRM2 SCOMBSSQ SCOPY SCSUM1 SCSUM SDISNA SDOT SDSDOT
      SECOND SGBBRD SGBCON SGBEQU SGBEQUB SGBMV SGBRFS SGBSV SGBSVX
      SGBTF2 SGBTRF SGBTRS SGEADD SGEBAK SGEBAL SGEBD2 SGEBRD SGECON
      SGEEQU SGEEQUB SGEES SGEESX SGEEV SGEEVX SGEHD2 SGEHRD SGEJSV
      SGELQ2 SGELQ SGELQF SGELQT3 SGELQT SGELS SGELSD SGELSS SGELSY
      SGEMLQ SGEMLQT SGEMM SGEMQR SGEMQRT SGEMV SGEQL2 SGEQLF SGEQP3
      SGEQR2 SGEQR2P SGEQR SGEQRF SGEQRFP SGEQRT2 SGEQRT3 SGEQRT SGER
      SGERFS SGERQ2 SGERQF SGESC2 SGESDD SGESV SGESVD SGESVDQ SGESVDX
      SGESVJ SGESVX SGETC2 SGETF2 SGETRF2 SGETRF SGETRI SGETRS SGETSLS
      SGGBAK SGGBAL SGGES3 SGGES SGGESX SGGEV3 SGGEV SGGEVX SGGGLM
      SGGHD3 SGGHRD SGGLSE SGGQRF SGGRQF SGGSVD3 SGGSVP3 SGSVJ0 SGSVJ1
      SGTCON SGTRFS SGTSV SGTSVX SGTTRF SGTTRS SGTTS2 SHGEQZ SHSEIN
      SHSEQR SIMATCOPY SISNAN SLABAD SLABRD SLACN2 SLACON SLACPY
      SLADIV1 SLADIV2 SLADIV SLAE2 SLAEBZ SLAED0 SLAED1 SLAED2 SLAED3
      SLAED4 SLAED5 SLAED6 SLAED7 SLAED8 SLAED9 SLAEDA SLAEIN SLAEV2
      SLAEXC SLAG2 SLAG2D SLAGGE SLAGS2 SLAGSY SLAGTF SLAGTM SLAGTS
      SLAGV2 SLAHILB SLAHQR SLAHR2 SLAIC1 SLAISNAN SLAKF2 SLALN2
      SLALS0 SLALSA SLALSD SLAMC3 SLAMCH SLAMRG SLAMSWLQ SLAMTSQR
      SLANEG SLANGB SLANGE SLANGT SLANHS SLANSB SLANSF SLANSP SLANST
      SLANSY SLANTB SLANTP SLANTR SLANV2 SLAORHRCOLGETRFNP2
      SLAORHRCOLGETRFNP SLAPLL SLAPMR SLAPMT SLAPY2 SLAPY3 SLAQGB
      SLAQGE SLAQP2 SLAQPS SLAQR0 SLAQR1 SLAQR2 SLAQR3 SLAQR4 SLAQR5
      SLAQSB SLAQSP SLAQSY SLAQTR SLAR1V SLAR2V SLARAN SLARF SLARFB
      SLARFG SLARFGP SLARFT SLARFX SLARFY SLARGE SLARGV SLARND SLARNV
      SLAROR SLAROT SLARRA SLARRB SLARRC SLARRD SLARRE SLARRF SLARRJ
      SLARRK SLARRR SLARRV SLARTG SLARTGP SLARTGS SLARTV SLARUV SLARZ
      SLARZB SLARZT SLAS2 SLASCL SLASD0 SLASD1 SLASD2 SLASD3 SLASD4
      SLASD5 SLASD6 SLASD7 SLASD8 SLASDA SLASDQ SLASDT SLASET SLASQ1
      SLASQ2 SLASQ3 SLASQ4 SLASQ5 SLASQ6 SLASR SLASRT SLASSQ SLASV2
      SLASWLQ SLASWP SLASY2 SLASYF SLASYFAA SLASYFRK SLASYFROOK SLATBS
      SLATDF SLATM1 SLATM2 SLATM3 SLATM5 SLATM6 SLATM7 SLATME SLATMR
      SLATMS SLATMT SLATPS SLATRD SLATRS SLATRZ SLATSQR SLAUU2 SLAUUM
      SMAX SMIN SNRM2 SOMATCOPY SOPGTR SOPMTR SORBDB1 SORBDB2 SORBDB3
      SORBDB4 SORBDB5 SORBDB6 SORBDB SORCSD2BY1 SORCSD SORG2L SORG2R
      SORGBR SORGHR SORGL2 SORGLQ SORGQL SORGQR SORGR2 SORGRQ SORGTR
      SORGTSQR SORHRCOL SORM22 SORM2L SORM2R SORMBR SORMHR SORML2
      SORMLQ SORMQL SORMQR SORMR2 SORMR3 SORMRQ SORMRZ SORMTR SPBCON
      SPBEQU SPBRFS SPBSTF SPBSV SPBSVX SPBTF2 SPBTRF SPBTRS SPFTRF
      SPFTRI SPFTRS SPOCON SPOEQU SPOEQUB SPORFS SPOSV SPOSVX SPOTF2
      SPOTRF2 SPOTRF SPOTRI SPOTRS SPPCON SPPEQU SPPRFS SPPSV SPPSVX
      SPPTRF SPPTRI SPPTRS SPSTF2 SPSTRF SPTCON SPTEQR SPTRFS SPTSV
      SPTSVX SPTTRF SPTTRS SPTTS2 SROT SROTG SROTM SROTMG SRSCL
      SSB2STKERNELS SSBEV SSBEV2STAGE SSBEVD SSBEVD2STAGE SSBEVX
      SSBEVX2STAGE SSBGST SSBGV SSBGVD SSBGVX SSBMV SSBTRD SSCAL SSFRK
      SSPCON SSPEV SSPEVD SSPEVX SSPGST SSPGV SSPGVD SSPGVX SSPMV
      SSPR2 SSPR SSPRFS SSPSV SSPSVX SSPTRD SSPTRF SSPTRI SSPTRS
      SSTEBZ SSTEDC SSTEGR SSTEIN SSTEMR SSTEQR SSTERF SSTEV SSTEVD
      SSTEVR SSTEVX SSUM SSWAP SSYCON SSYCON3 SSYCONROOK SSYCONV
      SSYCONVFROOK SSYEQUB SSYEV SSYEV2STAGE SSYEVD SSYEVD2STAGE
      SSYEVR SSYEVR2STAGE SSYEVX SSYEVX2STAGE SSYGS2 SSYGST SSYGV
      SSYGV2STAGE SSYGVD SSYGVX SSYMM SSYMV SSYR2 SSYR2K SSYR SSYRFS
      SSYRK SSYSV SSYSVAA SSYSVAA2STAGE SSYSVRK SSYSVROOK SSYSVX
      SSYSWAPR SSYTD2 SSYTF2 SSYTF2RK SSYTF2ROOK SSYTRD SSYTRD2STAGE
      SSYTRDSB2ST SSYTRDSY2SB SSYTRF SSYTRFAA SSYTRFAA2STAGE SSYTRFRK
      SSYTRFROOK SSYTRI2 SSYTRI2X SSYTRI SSYTRI3 SSYTRI3X SSYTRIROOK
      SSYTRS2 SSYTRS SSYTRS3 SSYTRSAA SSYTRSAA2STAGE SSYTRSROOK STBCON
      STBMV STBRFS STBSV STBTRS STFSM STFTRI STFTTP STFTTR STGEVC
      STGEX2 STGEXC STGSEN STGSJA STGSNA STGSY2 STGSYL STPCON STPLQT2
      STPLQT STPMLQT STPMQRT STPMV STPQRT2 STPQRT STPRFB STPRFS STPSV
      STPTRI STPTRS STPTTF STPTTR STRCON STREVC3 STREVC STREXC STRMM
      STRMV STRRFS STRSEN STRSM STRSNA STRSV STRSYL STRTI2 STRTRI
      STRTRS STRTTF STRTTP STZRZF XERBLA XERBLAARRAY ZAXPBY ZAXPY
      ZBBCSD ZBDSQR ZCGESV ZCOPY ZCPOSV ZDOTC ZDOTU ZDROT ZDRSCL
      ZDSCAL ZGBBRD ZGBCON ZGBEQU ZGBEQUB ZGBMV ZGBRFS ZGBSV ZGBSVX
      ZGBTF2 ZGBTRF ZGBTRS ZGEADD ZGEBAK ZGEBAL ZGEBD2 ZGEBRD ZGECON
      ZGEEQU ZGEEQUB ZGEES ZGEESX ZGEEV ZGEEVX ZGEHD2 ZGEHRD ZGEJSV
      ZGELQ2 ZGELQ ZGELQF ZGELQT3 ZGELQT ZGELS ZGELSD ZGELSS ZGELSY
      ZGEMLQ ZGEMLQT ZGEMM3M ZGEMM ZGEMQR ZGEMQRT ZGEMV ZGEQL2 ZGEQLF
      ZGEQP3 ZGEQR2 ZGEQR2P ZGEQR ZGEQRF ZGEQRFP ZGEQRT2 ZGEQRT3
      ZGEQRT ZGERC ZGERFS ZGERQ2 ZGERQF ZGERU ZGESC2 ZGESDD ZGESV
      ZGESVD ZGESVDQ ZGESVDX ZGESVJ ZGESVX ZGETC2 ZGETF2 ZGETRF2
      ZGETRF ZGETRI ZGETRS ZGETSLS ZGGBAK ZGGBAL ZGGES3 ZGGES ZGGESX
      ZGGEV3 ZGGEV ZGGEVX ZGGGLM ZGGHD3 ZGGHRD ZGGLSE ZGGQRF ZGGRQF
      ZGGSVD3 ZGGSVP3 ZGSVJ0 ZGSVJ1 ZGTCON ZGTRFS ZGTSV ZGTSVX ZGTTRF
      ZGTTRS ZGTTS2 ZHB2STKERNELS ZHBEV ZHBEV2STAGE ZHBEVD
      ZHBEVD2STAGE ZHBEVX ZHBEVX2STAGE ZHBGST ZHBGV ZHBGVD ZHBGVX
      ZHBMV ZHBTRD ZHECON ZHECON3 ZHECONROOK ZHEEQUB ZHEEV ZHEEV2STAGE
      ZHEEVD ZHEEVD2STAGE ZHEEVR ZHEEVR2STAGE ZHEEVX ZHEEVX2STAGE
      ZHEGS2 ZHEGST ZHEGV ZHEGV2STAGE ZHEGVD ZHEGVX ZHEMM ZHEMV ZHER2
      ZHER2K ZHER ZHERFS ZHERK ZHESV ZHESVAA ZHESVAA2STAGE ZHESVRK
      ZHESVROOK ZHESVX ZHESWAPR ZHETD2 ZHETF2 ZHETF2RK ZHETF2ROOK
      ZHETRD ZHETRD2STAGE ZHETRDHB2ST ZHETRDHE2HB ZHETRF ZHETRFAA
      ZHETRFAA2STAGE ZHETRFRK ZHETRFROOK ZHETRI2 ZHETRI2X ZHETRI
      ZHETRI3 ZHETRI3X ZHETRIROOK ZHETRS2 ZHETRS ZHETRS3 ZHETRSAA
      ZHETRSAA2STAGE ZHETRSROOK ZHFRK ZHGEQZ ZHPCON ZHPEV ZHPEVD
      ZHPEVX ZHPGST ZHPGV ZHPGVD ZHPGVX ZHPMV ZHPR2 ZHPR ZHPRFS ZHPSV
      ZHPSVX ZHPTRD ZHPTRF ZHPTRI ZHPTRS ZHSEIN ZHSEQR ZIMATCOPY
      ZLABRD ZLACGV ZLACN2 ZLACON ZLACP2 ZLACPY ZLACRM ZLACRT ZLADIV
      ZLAED0 ZLAED7 ZLAED8 ZLAEIN ZLAESY ZLAEV2 ZLAG2C ZLAGGE ZLAGHE
      ZLAGS2 ZLAGSY ZLAGTM ZLAHEF ZLAHEFAA ZLAHEFRK ZLAHEFROOK ZLAHILB
      ZLAHQR ZLAHR2 ZLAIC1 ZLAKF2 ZLALS0 ZLALSA ZLALSD ZLAMSWLQ
      ZLAMTSQR ZLANGB ZLANGE ZLANGT ZLANHB ZLANHE ZLANHF ZLANHP ZLANHS
      ZLANHT ZLANSB ZLANSP ZLANSY ZLANTB ZLANTP ZLANTR ZLAPLL ZLAPMR
      ZLAPMT ZLAQGB ZLAQGE ZLAQHB ZLAQHE ZLAQHP ZLAQP2 ZLAQPS ZLAQR0
      ZLAQR1 ZLAQR2 ZLAQR3 ZLAQR4 ZLAQR5 ZLAQSB ZLAQSP ZLAQSY ZLAR1V
      ZLAR2V ZLARCM ZLARF ZLARFB ZLARFG ZLARFGP ZLARFT ZLARFX ZLARFY
      ZLARGE ZLARGV ZLARND ZLARNV ZLAROR ZLAROT ZLARRV ZLARTG ZLARTV
      ZLARZ ZLARZB ZLARZT ZLASCL ZLASET ZLASR ZLASSQ ZLASWLQ ZLASWP
      ZLASYF ZLASYFAA ZLASYFRK ZLASYFROOK ZLAT2C ZLATBS ZLATDF ZLATM1
      ZLATM2 ZLATM3 ZLATM5 ZLATM6 ZLATME ZLATMR ZLATMS ZLATMT ZLATPS
      ZLATRD ZLATRS ZLATRZ ZLATSQR ZLAUNHRCOLGETRFNP2
      ZLAUNHRCOLGETRFNP ZLAUU2 ZLAUUM ZOMATCOPY ZPBCON ZPBEQU ZPBRFS
      ZPBSTF ZPBSV ZPBSVX ZPBTF2 ZPBTRF ZPBTRS ZPFTRF ZPFTRI ZPFTRS
      ZPOCON ZPOEQU ZPOEQUB ZPORFS ZPOSV ZPOSVX ZPOTF2 ZPOTRF2 ZPOTRF
      ZPOTRI ZPOTRS ZPPCON ZPPEQU ZPPRFS ZPPSV ZPPSVX ZPPTRF ZPPTRI
      ZPPTRS ZPSTF2 ZPSTRF ZPTCON ZPTEQR ZPTRFS ZPTSV ZPTSVX ZPTTRF
      ZPTTRS ZPTTS2 ZROT ZROTG ZSBMV ZSCAL ZSPCON ZSPMV ZSPR2 ZSPR
      ZSPRFS ZSPSV ZSPSVX ZSPTRF ZSPTRI ZSPTRS ZSTEDC ZSTEGR ZSTEIN
      ZSTEMR ZSTEQR ZSWAP ZSYCON ZSYCON3 ZSYCONROOK ZSYCONV ZSYCONVF
      ZSYCONVFROOK ZSYEQUB ZSYMM ZSYMV ZSYR2 ZSYR2K ZSYR ZSYRFS ZSYRK
      ZSYSV ZSYSVAA ZSYSVAA2STAGE ZSYSVRK ZSYSVROOK ZSYSVX ZSYSWAPR
      ZSYTF2 ZSYTF2RK ZSYTF2ROOK ZSYTRF ZSYTRFAA ZSYTRFAA2STAGE
      ZSYTRFRK ZSYTRFROOK ZSYTRI2 ZSYTRI2X ZSYTRI ZSYTRI3 ZSYTRI3X
      ZSYTRIROOK ZSYTRS2 ZSYTRS ZSYTRS3 ZSYTRSAA ZSYTRSAA2STAGE
      ZSYTRSROOK ZTBCON ZTBMV ZTBRFS ZTBSV ZTBTRS ZTFSM ZTFTRI ZTFTTP
      ZTFTTR ZTGEVC ZTGEX2 ZTGEXC ZTGSEN ZTGSJA ZTGSNA ZTGSY2 ZTGSYL
      ZTPCON ZTPLQT2 ZTPLQT ZTPMLQT ZTPMQRT ZTPMV ZTPQRT2 ZTPQRT
      ZTPRFB ZTPRFS ZTPSV ZTPTRI ZTPTRS ZTPTTF ZTPTTR ZTRCON ZTREVC3
      ZTREVC ZTREXC ZTRMM ZTRMV ZTRRFS ZTRSEN ZTRSM ZTRSNA ZTRSV
      ZTRSYL ZTRTI2 ZTRTRI ZTRTRS ZTRTTF ZTRTTP ZTZRZF ZUNBDB1 ZUNBDB2
      ZUNBDB3 ZUNBDB4 ZUNBDB5 ZUNBDB6 ZUNBDB ZUNCSD2BY1 ZUNCSD ZUNG2L
      ZUNG2R ZUNGBR ZUNGHR ZUNGL2 ZUNGLQ ZUNGQL ZUNGQR ZUNGR2 ZUNGRQ
      ZUNGTR ZUNGTSQR ZUNHRCOL ZUNM22 ZUNM2L ZUNM2R ZUNMBR ZUNMHR
      ZUNML2 ZUNMLQ ZUNMQL ZUNMQR ZUNMR2 ZUNMR3 ZUNMRQ ZUNMRZ ZUNMTR
      ZUPGTR ZUPMTR sisnan disnan)

      for sym in ${syms[@]}; do
         FFLAGS+=("-D${sym}=${sym}_64")
      done

      CMAKE_FLAGS+=(-DCMAKE_Fortran_FLAGS=\"${FFLAGS[*]}\")
    fi

    mkdir build && cd build
    cmake .. "${CMAKE_FLAGS[@]}" \
       -DCMAKE_INSTALL_PREFIX="$prefix" \
       -DCMAKE_FIND_ROOT_PATH="$prefix" \
       -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
       -DCMAKE_BUILD_TYPE=Release \
       -DBUILD_SHARED_LIBS=ON \
       -DBLAS_LIBRARIES="-L${libdir} -lblastrampoline"

    make -j${nproc} all
    make install
    """
end

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())
filter!(p -> !(arch(p) == "aarch64" && Sys.islinux(p) && libgfortran_version(p) == v"3"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("liblapack", :liblapack),
]

# Dependencies that must be installed before this package can be built
dependencies = [
        Dependency("CompilerSupportLibraries_jll")
        Dependency("libblastrampoline_jll"; compat="5.1.1")
]
