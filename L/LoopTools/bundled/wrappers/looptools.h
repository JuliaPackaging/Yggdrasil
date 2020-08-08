#if 0
looptools.h
the header file for Fortran with all definitions for LoopTools
this file is part of LoopTools
last modified 8 Nov 17 th
#endif


#ifndef LOOPTOOLS_H
#define LOOPTOOLS_H

#define aa0 1
#define aa00 4
#define Naa 6

#define bb0 1
#define bb1 4
#define bb00 7
#define bb11 10
#define bb001 13
#define bb111 16
#define dbb0 19
#define dbb1 22
#define dbb00 25
#define dbb11 28
#define dbb001 31
#define Nbb 33

#define cc0 1
#define cc1 4
#define cc2 7
#define cc00 10
#define cc11 13
#define cc12 16
#define cc22 19
#define cc001 22
#define cc002 25
#define cc111 28
#define cc112 31
#define cc122 34
#define cc222 37
#define cc0000 40
#define cc0011 43
#define cc0012 46
#define cc0022 49
#define cc1111 52
#define cc1112 55
#define cc1122 58
#define cc1222 61
#define cc2222 64
#define Ncc 66

#define dd0 1
#define dd1 4
#define dd2 7
#define dd3 10
#define dd00 13
#define dd11 16
#define dd12 19
#define dd13 22
#define dd22 25
#define dd23 28
#define dd33 31
#define dd001 34
#define dd002 37
#define dd003 40
#define dd111 43
#define dd112 46
#define dd113 49
#define dd122 52
#define dd123 55
#define dd133 58
#define dd222 61
#define dd223 64
#define dd233 67
#define dd333 70
#define dd0000 73
#define dd0011 76
#define dd0012 79
#define dd0013 82
#define dd0022 85
#define dd0023 88
#define dd0033 91
#define dd1111 94
#define dd1112 97
#define dd1113 100
#define dd1122 103
#define dd1123 106
#define dd1133 109
#define dd1222 112
#define dd1223 115
#define dd1233 118
#define dd1333 121
#define dd2222 124
#define dd2223 127
#define dd2233 130
#define dd2333 133
#define dd3333 136
#define dd00001 139
#define dd00002 142
#define dd00003 145
#define dd00111 148
#define dd00112 151
#define dd00113 154
#define dd00122 157
#define dd00123 160
#define dd00133 163
#define dd00222 166
#define dd00223 169
#define dd00233 172
#define dd00333 175
#define dd11111 178
#define dd11112 181
#define dd11113 184
#define dd11122 187
#define dd11123 190
#define dd11133 193
#define dd11222 196
#define dd11223 199
#define dd11233 202
#define dd11333 205
#define dd12222 208
#define dd12223 211
#define dd12233 214
#define dd12333 217
#define dd13333 220
#define dd22222 223
#define dd22223 226
#define dd22233 229
#define dd22333 232
#define dd23333 235
#define dd33333 238
#define Ndd 240

#define ee0 1
#define ee1 4
#define ee2 7
#define ee3 10
#define ee4 13
#define ee00 16
#define ee11 19
#define ee12 22
#define ee13 25
#define ee14 28
#define ee22 31
#define ee23 34
#define ee24 37
#define ee33 40
#define ee34 43
#define ee44 46
#define ee001 49
#define ee002 52
#define ee003 55
#define ee004 58
#define ee111 61
#define ee112 64
#define ee113 67
#define ee114 70
#define ee122 73
#define ee123 76
#define ee124 79
#define ee133 82
#define ee134 85
#define ee144 88
#define ee222 91
#define ee223 94
#define ee224 97
#define ee233 100
#define ee234 103
#define ee244 106
#define ee333 109
#define ee334 112
#define ee344 115
#define ee444 118
#define ee0000 121
#define ee0011 124
#define ee0012 127
#define ee0013 130
#define ee0014 133
#define ee0022 136
#define ee0023 139
#define ee0024 142
#define ee0033 145
#define ee0034 148
#define ee0044 151
#define ee1111 154
#define ee1112 157
#define ee1113 160
#define ee1114 163
#define ee1122 166
#define ee1123 169
#define ee1124 172
#define ee1133 175
#define ee1134 178
#define ee1144 181
#define ee1222 184
#define ee1223 187
#define ee1224 190
#define ee1233 193
#define ee1234 196
#define ee1244 199
#define ee1333 202
#define ee1334 205
#define ee1344 208
#define ee1444 211
#define ee2222 214
#define ee2223 217
#define ee2224 220
#define ee2233 223
#define ee2234 226
#define ee2244 229
#define ee2333 232
#define ee2334 235
#define ee2344 238
#define ee2444 241
#define ee3333 244
#define ee3334 247
#define ee3344 250
#define ee3444 253
#define ee4444 256
#define Nee 258

#define KeyA0 2**0
#define KeyBget 2**2
#define KeyC0 2**4
#define KeyD0 2**6
#define KeyD0C 2**8
#define KeyE0 2**10
#define KeyEget 2**12
#define KeyEgetC 2**14
#define KeyAll 21845

#define DebugA 2**0
#define DebugB 2**1
#define DebugC 2**2
#define DebugD 2**3
#define DebugE 2**4
#define DebugAll 31

#define memindex integer*8
#ifndef ComplexType
#define ComplexType double complex
#endif
#ifndef RealType
#define RealType double precision
#endif

#define Aval(id,p) cache(p+id,1)
#define AvalC(id,p) cache(p+id,2)
#define Bval(id,p) cache(p+id,3)
#define BvalC(id,p) cache(p+id,4)
#define Cval(id,p) cache(p+id,5)
#define CvalC(id,p) cache(p+id,6)
#define Dval(id,p) cache(p+id,7)
#define DvalC(id,p) cache(p+id,8)
#define Eval(id,p) cache(p+id,9)
#define EvalC(id,p) cache(p+id,10)

#define Ccache 0
#define Dcache 0

#endif

	integer ncaches
	parameter (ncaches = 10)

	ComplexType cache(2,ncaches)
	common /ltvars/ cache

	ComplexType A0i, A0, A0C, A00, A00C, B0i, B0iC
	ComplexType B0, B1, B00, B11, B001, B111
	ComplexType B0C, B1C, B00C, B11C, B001C, B111C
	ComplexType DB0, DB1, DB00, DB11, DB001
	ComplexType DB0C, DB1C, DB00C, DB11C, DB001C
	ComplexType C0, C0C, C0i, C0iC
	ComplexType D0, D0C, D0i, D0iC
	ComplexType E0, E0C, E0i, E0iC
	ComplexType Li2, Li2C, Li2omx, Li2omxC
	memindex Aget, AgetC, Bget, BgetC, Cget, CgetC
	memindex Dget, DgetC, Eget, EgetC
	RealType getmudim, getdelta, getlambda, getminmass
	RealType getmaxdev
	integer getepsi, getwarndigits, geterrdigits
	integer getversionkey, getdebugkey
	integer getcachelast

	external A0i, A0, A0C, A00, A00C, B0i, B0iC
	external B0, B1, B00, B11, B001, B111
	external B0C, B1C, B00C, B11C, B001C, B111C
	external DB0, DB1, DB00, DB11, DB001
	external DB0C, DB1C, DB00C, DB11C, DB001C
	external C0, C0C, C0i, C0iC
	external D0, D0C, D0i, D0iC
	external E0, E0C, E0i, E0iC
	external Li2, Li2C, Li2omx, Li2omxC
	external Aget, AgetC, Bget, BgetC, Cget, CgetC
	external Dget, DgetC, Eget, EgetC
	external getmudim, getdelta, getlambda, getminmass
	external getmaxdev
	external getepsi, getwarndigits, geterrdigits
	external getversionkey, getdebugkey
	external getcachelast

