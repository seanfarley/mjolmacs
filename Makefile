DEBUG=-g
CFLAGS=-I/usr/local/include -Wall -Wextra -framework Foundation -framework AppKit -framework UserNotifications -framework Security
LDFLAGS=-L./CarbonHotKey -lhotkey -Xlinker -rpath -Xlinker @rpath/CarbonHotKey

.PHONY: CarbonHotKey all mjolmacs-module clean lint

all: mjolmacs-module

CarbonHotKey/libhotkey.so:
	$(MAKE) -C CarbonHotKey

mjolmacs-module: CarbonHotKey/libhotkey.so
	$(CC) $(DEBUG) $(CFLAGS) $(LDFLAGS) -shared -o $@.so *.m

lint:
	find . -type f '(' -name '*.m' -or -name '*.h' ')' -exec clang-format --dry-run '{}' ';'

clean:
	$(MAKE) -C CarbonHotKey clean
	$(RM) -r $(TARGET) $(OBJS) $(DEPS) *.dylib *.so *.dSYM a.out *.o *.framework
