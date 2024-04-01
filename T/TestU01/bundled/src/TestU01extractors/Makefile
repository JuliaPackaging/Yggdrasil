install:
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) -O2 -shared -fPIC -I $(prefix)/include extractors.c -o $(libdir)/libtestu01extractors.$(dlext) -L $(prefix)/lib $(RPATH) -lmylib -lprobdist -ltestu01

# Makefile debugging trick:
# call print-VARIABLE to see the runtime value of any variable
print-%:
	@echo '$*=$($*)'
