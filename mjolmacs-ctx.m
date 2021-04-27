#import "mjolmacs-ctx.h"

@implementation MjolmacsCtx

- (id)init {
  self = [super init];
  if (self) {
    funcs = [[NSMutableDictionary alloc] init];
    pipe = nil;
  }

  return self;
}

- (void)hotkeyWithEvent:(NSEvent *)hkEvent object:(id)anObject {
  NSLog(@"Firing -[%@ %@]", NSStringFromClass([self class]),
        NSStringFromSelector(_cmd));
  NSLog(@"Hotkey event: %@", hkEvent);
  NSLog(@"Object: %@", anObject);
}

- (void)openChannel:(int)fd {
  if (!pipe) {
    pipe = [[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:YES];
  }
}

- (void)runLisp:(NSString *)lisp {
  NSString *nt_lisp = [NSString stringWithFormat:@"%@\0", lisp];
  [self->pipe writeData:[nt_lisp dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
