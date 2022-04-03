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

  NSString *func = self.funcs[hk_m];

  NSString *lisp = [NSString
      stringWithFormat:@"(let ((maxarg (cdr (func-arity '%@))))"
                       @"  (if (and (numberp maxarg) (= maxarg 0))"
                       @"      (%@)"
                       @"    (%@ %d)))",
                       func, func, func, [runningApp processIdentifier]];

  // NSLog(@"LISP: %@", lisp);
  [self runLisp:lisp];
}

// this is needed to show notification banners while our app is in the
// foreground; else they will not popup (but will still be in the notification
// sidebar)
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:
             (void (^)(UNNotificationPresentationOptions options))
                 completionHandler {
  completionHandler(UNNotificationPresentationOptionBanner);
}

- (void)showMyWindow:(NSString *)strMsg font:(NSFont *)font {
  NSSize boundingSize =
      [strMsg sizeWithAttributes:@{NSFontAttributeName : font}];

  // add some padding else the text won't quite fit; perhaps a difference in how
  // Apple actually computes the size for a window around text
  boundingSize.width += 20;
  boundingSize.height += 5;

  NSRect boundingRect =
      NSMakeRect(0.0, 0.0, boundingSize.width, boundingSize.height);

  // unknown why these offsets are so weird
  NSTextField *strTextField = [[NSTextField alloc]
      initWithFrame:NSMakeRect(-5.0, -8.0, boundingSize.width,
                               boundingSize.height)];
  strTextField.bezeled = NO;
  strTextField.editable = NO;
  strTextField.drawsBackground = NO;
  strTextField.textColor = NSColor.whiteColor;
  strTextField.font = font;
  strTextField.stringValue = strMsg;
  strTextField.alignment = NSTextAlignmentCenter;

  NSBox *myBox = [[NSBox alloc] initWithFrame:boundingRect];
  myBox.boxType = NSBoxCustom;
  myBox.cornerRadius = 15.0;
  // mimics the default color of the system HUD background
  myBox.fillColor = [NSColor colorWithCalibratedWhite:0.12549 alpha:0.85];
  [myBox addSubview:strTextField];

  self.textWindow =
      [[NSPanel alloc] initWithContentRect:boundingRect
                                 styleMask:NSWindowStyleMaskHUDWindow |
                                           NSWindowStyleMaskNonactivatingPanel |
                                           NSWindowStyleMaskUtilityWindow
                                   backing:NSBackingStoreBuffered
                                     defer:YES];
  self.textWindow.opaque = NO;
  self.textWindow.backgroundColor = NSColor.clearColor;
  self.textWindow.level = NSStatusWindowLevel;
  [self.textWindow.contentView addSubview:myBox];

  [self.textWindow center];
  [self.textWindow makeKeyAndOrderFront:[NSApp mainWindow]];

  [NSTimer scheduledTimerWithTimeInterval:3
                                   target:self
                                 selector:@selector(closeMyWindow)
                                 userInfo:nil
                                  repeats:NO];
}

- (void)closeMyWindow {
  // could possibly return nil / t if myWindow is actually opened (and then
  // closed)
  [self.textWindow close];
}

@end
