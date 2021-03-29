CFLAGS=-Wall -Wextra
DEBUG=-g
MAC_LIB = edda

.PHONY: $(MAC_LIB)

edda:
	swift build --package-path $@

$(MAC_LIB)/.build/debug/$(MAC_LIB).build/$(MAC_LIB)-Swift.h: $(MAC_LIB)

$(MAC_LIB).h: $(MAC_LIB)/.build/debug/$(MAC_LIB).build/$(MAC_LIB)-Swift.h
	cp $< $@

clean:
	@$(RM) -r $(TARGET) $(OBJS) $(DEPS) *.dylib *.so *.dSYM a.out *.o $(MAC_LIB)/.build $(MAC_LIB).h
