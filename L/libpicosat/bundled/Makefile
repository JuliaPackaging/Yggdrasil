CFLAGS += -DNDEBUG -O3 -fPIC
CFLAGS += -DTRACE -DNGETRUSAGE -DNALLSIGNALS

all: picosat picomcs picomus picogcnf libpicosat.$(dlext)

clean:
	rm -f picosat picomcs picomus picogcnf
	rm -f *.exe *.s *.o *.a *.so *.plist
	rm -f Makefile config.h
	rm -f gmon.out *~

analyze:
	clang --analyze $(CFLAGS) *.c *.h

picosat: libpicosat.$(dlext) app.o main.o
	$(CC) $(CFLAGS) -o $@ main.o app.o -L. -lpicosat

picomcs: libpicosat.$(dlext) picomcs.o
	$(CC) $(CFLAGS) -o $@ picomcs.o -L. -lpicosat

picomus: libpicosat.$(dlext) picomus.o
	$(CC) $(CFLAGS) -o $@ picomus.o -L. -lpicosat

picogcnf: libpicosat.$(dlext) picogcnf.o
	$(CC) $(CFLAGS) -o $@ picogcnf.o -L. -lpicosat

app.o: app.c picosat.h Makefile
	$(CC) $(CFLAGS) -c $<

picomcs.o: picomcs.c picosat.h Makefile
	$(CC) $(CFLAGS) -c $<

picomus.o: picomus.c picosat.h Makefile
	$(CC) $(CFLAGS) -c $<

picogcnf.o: picogcnf.c picosat.h Makefile
	$(CC) $(CFLAGS) -c $<

main.o: main.c picosat.h Makefile
	$(CC) $(CFLAGS) -c $<

picosat.o: picosat.c picosat.h Makefile
	$(CC) $(CFLAGS) -c $<

version.o: version.c config.h Makefile
	$(CC) $(CFLAGS) -c $<

config.h: Makefile VERSION mkconfig.sh # and actually picosat.c
	rm -f $@; sed -i -e 's$PICOSAT_CC$PICOSAT_CC "${CC}"$g' -e 's$PICOSAT_CFLAGS "${CFLAGS}"$g'

libpicosat.$(dlext): picosat.o version.o
	$(CC) $(CFLAGS) -shared -o $@ picosat.o version.o

install: libpicosat.$(dlext)
	install -d $(libdir) $(includedir)
	install libpicosat.$(dlext) $(libdir)
	install picosat.h $(includedir)

.PHONY: all clean install
