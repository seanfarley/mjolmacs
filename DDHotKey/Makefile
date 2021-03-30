DEBUG=-g
CFLAGS=-Wall -Wextra -framework Carbon -framework Cocoa
LDFLAGS=-Xlinker -install_name -Xlinker DDHotKey/libhotkey.so

.PHONY: all

all: libhotkey.so

libhotkey.so:
	$(CC) $(DEBUG) $(CFLAGS) $(LDFLAGS) -shared -o $@ *.m

clean:
	@$(RM) -r $(TARGET) $(OBJS) $(DEPS) *.dylib *.so *.dSYM a.out *.o
