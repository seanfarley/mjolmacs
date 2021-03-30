MAC_LIB = edda
MAC_LIB_BUILD_PATH = $(MAC_LIB)/.build/debug/$(MAC_LIB).build
DEBUG=-g
CFLAGS=-Wall -Wextra
LDFLAGS=-L. -l$(MAC_LIB) -Xlinker -rpath -Xlinker .

.PHONY: $(MAC_LIB) all mjolmacs

all: mjolmacs

mjolmacs: $(MAC_LIB)/$(MAC_LIB)-Swift.h
	$(CC) $(DEBUG) $(CFLAGS) $(LDFLAGS) -dynamiclib -o $@.so $@.m

$(MAC_LIB):
	swift build --package-path $@
	cp $(MAC_LIB_BUILD_PATH)/../lib$(MAC_LIB).dylib .

$(MAC_LIB_BUILD_PATH)/$(MAC_LIB)-Swift.h: $(MAC_LIB)

$(MAC_LIB)/$(MAC_LIB)-Swift.h: $(MAC_LIB_BUILD_PATH)/$(MAC_LIB)-Swift.h
	cp $< $@

$(MAC_LIB).m:

clean:
	@$(RM) -r $(TARGET) $(OBJS) $(DEPS) *.dylib *.so *.dSYM a.out *.o
	@$(RM) -r $(MAC_LIB)/.build
	@$(RM) $(MAC_LIB)/$(MAC_LIB)-Swift.h
