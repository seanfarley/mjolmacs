#import "CarbonHotKey/CarbonHotKeyCenter.h"

#import <Cocoa/Cocoa.h>

@interface MjolmacsCtx : NSObject {
  NSMutableDictionary *funcs;
  NSFileHandle *pipe;
}

- (void)openChannel:(int)fd;
- (void)runLisp:(NSString *)lisp;

@end
