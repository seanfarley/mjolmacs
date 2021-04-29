#import "mjolmacs-ctx.h"
#import "mjolmacs-utils.h"

@implementation MjolmacsCtx

- (id)init {
  self = [super init];
  if (self) {
    _funcs = [[NSMutableDictionary alloc] init];
    _pipe = nil;
  }

  return self;
}

- (void)dealloc {
  NSLog(@"Actually got to dealloc!");
  [_funcs dealloc];
  [_pipe dealloc];
  [super dealloc];
}

- (void)openChannel:(int)fd {
  if (!_pipe) {
    _pipe = [[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:YES];
  }
}

- (void)runLisp:(NSString *)lisp {
  NSString *nt_lisp = [NSString stringWithFormat:@"%@\0", lisp];
  [_pipe writeData:[nt_lisp dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)hotkeyWithEvent:(NSEvent *)hkEvent object:(id)anObject {
  NSLog(@"Firing -[%@ %@]", NSStringFromClass([self class]),
        NSStringFromSelector(_cmd));
  NSLog(@"Hotkey event: %@", hkEvent);
  NSLog(@"self: %@", self);
  NSLog(@"Object: %@", anObject);

  MjolmacsKey *hk_m = [MjolmacsKey keyWithMods:hkEvent.keyCode
                                      modifier:hkEvent.modifierFlags];

  NSRunningApplication *runningApp =
      [[NSWorkspace sharedWorkspace] frontmostApplication];

  NSString *lisp = [NSString stringWithFormat:@"(%@ %d)", self.funcs[hk_m],
                                              [runningApp processIdentifier]];

  [self runLisp:lisp];
}

@end
