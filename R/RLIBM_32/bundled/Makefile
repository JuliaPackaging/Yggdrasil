CFLAGS = -std=c11 -O3 -fPIC

floatFNames = log log2 log10 exp exp2 exp10 sinh cosh sinpi cospi log2_8 log10_8

floatSrcDir = source/float
floatObjDir = obj/float
libDir = lib

floatSrc = $(patsubst %, $(floatSrcDir)/%.c, $(floatFNames))
floatObj = $(patsubst %, $(floatObjDir)/%.o, $(floatFNames))

all: floatmlib

$(floatObjDir)/%.o: $(floatSrcDir)/%.c
	@mkdir -p $(floatObjDir)
	$(CC) $(CFLAGS) -c $^ -Iinclude/ -o $@

$(libDir)/floatMathLib.$(dlext): $(floatObj)
	@mkdir -p $(libDir)
	$(CC) -shared $^ -o $@

install: all
	install -Dm755 $(libDir)/floatMathLib.$(dlext) $(libdir)/floatMathLib.$(dlext)

floatmlib: $(libDir)/floatMathLib.$(dlext)

clean:
	rm -rf obj lib *.dSYM

.PHONY: all clean floatmlib install
