include mkinc.mak
CFLAGS=-O2
CPPFLAGS=-Iinclude
all: libstemmer.$(dlext) libstemmer.o stemwords$(exeext)
$(bindir):
	mkdir -p $(bindir)
$(libdir):
	mkdir -p $(libdir)
libstemmer.o: $(snowball_sources:.c=.o)
	$(AR) -cru $@ $^
libstemmer.$(dlext): libstemmer.o
	$(CC) -shared $(CFLAGS) -o $@ $(LDFLAGS) $^
stemwords$(exeext): examples/stemwords.o libstemmer.o
	$(CC) $(CFLAGS) -o $@ $^
install-libstemmer: $(libdir) libstemmer.$(dlext)
	cp libstemmer.$(dlext) $(libdir)/
install-stemwords: $(bindir) stemwords$(exeext)
	cp stemwords$(exeext) $(bindir)/
install: install-stemwords install-libstemmer
clean:
	rm -rf libstemmer.so stemwords *.o src_c/*.o examples/*.o runtime/*.o libstemmer/*.o $(bindir) $(libdir)
