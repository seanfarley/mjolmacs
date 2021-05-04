#import "mjolmacs-ctx.h"
#import "mjolmacs-utils.h"

#import <UserNotifications/UserNotifications.h>

@implementation MjolmacsCtx

- (id)init {
  self = [super init];
  if (self) {
    _funcs = [[NSMutableDictionary alloc] init];
    _pipe = nil;
    _isMacApp = NO;
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

// this is needed to show notification banners while our app is in the
// forebround; else they will not popup (but will still be in the notification
// sidebar)
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:
             (void (^)(UNNotificationPresentationOptions options))
                 completionHandler {
  completionHandler(UNNotificationPresentationOptionBanner);
}

@end
