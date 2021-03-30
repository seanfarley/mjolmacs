DEBUG=-g
CFLAGS=-I/usr/local/include -Wall -Wextra -framework Foundation
LDFLAGS=-L./DDHotKey -lhotkey -Xlinker -rpath -Xlinker @rpath/DDHotKey

.PHONY: DDHotKey all mjolmacs clean

all: mjolmacs

DDHotKey/libhotkey.so:
	$(MAKE) -C DDHotKey

mjolmacs: DDHotKey/libhotkey.so
	$(CC) $(DEBUG) $(CFLAGS) $(LDFLAGS) -shared -o $@.so $@.m

clean:
	$(MAKE) -C DDHotKey clean
	@$(RM) -r $(TARGET) $(OBJS) $(DEPS) *.dylib *.so *.dSYM a.out *.o *.framework
