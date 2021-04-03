DEBUG=-g
CFLAGS=-I/usr/local/include -Wall -Wextra -framework Foundation
LDFLAGS=-L./CarbonHotKey -lhotkey -Xlinker -rpath -Xlinker @rpath/CarbonHotKey

.PHONY: CarbonHotKey all mjolmacs-module clean

all: mjolmacs-module

CarbonHotKey/libhotkey.so:
	$(MAKE) -C CarbonHotKey

mjolmacs-module: CarbonHotKey/libhotkey.so
	$(CC) $(DEBUG) $(CFLAGS) $(LDFLAGS) -shared -o $@.so $@.m

clean:
	$(MAKE) -C CarbonHotKey clean
	$(RM) -r $(TARGET) $(OBJS) $(DEPS) *.dylib *.so *.dSYM a.out *.o *.framework
