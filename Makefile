MAC_LIB = edda
MAC_LIB_BUILD_PATH = $(MAC_LIB)/.build/debug/$(MAC_LIB).build
DEBUG=-g
CFLAGS=-Wall -Wextra
LDFLAGS=-L$(MAC_LIB) -l$(MAC_LIB)
# why doesn't this work?
#-Xlinker -rpath -Xlinker $(PWD)/$(MAC_LIB)/
#-Wl,-rpath,$(PWD)/$(MAC_LIB)

.PHONY: $(MAC_LIB) all mjolmacs

all: mjolmacs

mjolmacs: $(MAC_LIB)/$(MAC_LIB)-Swift.h
	$(CC) $(DEBUG) $(CFLAGS) $(LDFLAGS) -dynamiclib -o $@.so $@.m
	install_name_tool -change lib$(MAC_LIB).dylib $(MAC_LIB)/lib$(MAC_LIB).dylib $@.so

$(MAC_LIB):
	swift build -Xswiftc -emit-library --package-path $@

$(MAC_LIB_BUILD_PATH)/$(MAC_LIB)-Swift.h: $(MAC_LIB)

$(MAC_LIB)/$(MAC_LIB)-Swift.h: $(MAC_LIB_BUILD_PATH)/$(MAC_LIB)-Swift.h
	cp $< $@

$(MAC_LIB).m:

clean:
	@$(RM) -r $(TARGET) $(OBJS) $(DEPS) *.dylib *.so *.dSYM a.out *.o
	@$(RM) -r $(MAC_LIB)/.build
	@$(RM) -r $(MAC_LIB)/lib$(MAC_LIB).dylib*
	@$(RM) $(MAC_LIB)/$(MAC_LIB)-Swift.h
