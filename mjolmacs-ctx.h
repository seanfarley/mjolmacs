#import "CarbonHotKey/CarbonHotKeyCenter.h"

#import <Cocoa/Cocoa.h>

@interface MjolmacsCtx : NSObject {
}

@property(strong) NSMutableDictionary *funcs;
@property(strong) NSFileHandle *pipe;

// bool of emacs running as a mac app (i.e. with the .app extension)
@property BOOL isMacApp;

- (void)openChannel:(int)fd;
- (void)runLisp:(NSString *)lisp;

@end
